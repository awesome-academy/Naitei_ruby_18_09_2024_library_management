class RequestsController < ApplicationController
  include ApplicationHelper
  include RequestsHelper

  before_action :require_login
  before_action :has_unreturned_books?, only: :create
  before_action :load_selected_books, only: :new
  before_action :load_request_to_destroy, :correct_user,
                :is_pending?, only: :destroy
  before_action :load_request_to_handle, :validate_action_allowed, only: :handle

  def index
    @pagy, @requests = if all_requests_accessible?
                         pagy Request.by_status.includes(:books, :borrower),
                              limit: Settings.default_pagination
                       else
                         pagy current_user.borrow_requests
                                          .newest.includes(:books),
                              limit: Settings.default_pagination
                       end
  end

  def new
    @request = Request.new
  end

  def create
    selected_books = request_params[:selected_books]&.map(&:to_i)

    unless valid_borrow_amount? selected_books
      load_selected_books
      render :new, status: :unprocessable_entity and return
    end

    process_create_request selected_books
  end

  def destroy
    if @request.destroy
      flash[:emerald] = t "success.request_cancelled"
    else
      flash[:red] = t "error.cant_cancel_request"
    end
    redirect_to request.referer || root_url
  end

  def handle
    case params[:status].to_sym
    when :borrowing, :returned
      process_accept_or_return_request
    when :declined
      unless process_decline_request
        handle_invalid_destroy_or_handle t("error.missing_reason") and return
      end
    when :overdue
      change_status
    else
      handle_invalid_destroy_or_handle t "error.invalid_action" and return
    end
    handle_change_status_success
  end

  private

  def request_params
    params.require(:request).permit(Request::PERMITTED_PARAMS)
  end

  def load_selected_books
    @selected_books = current_user.selected_books
                                  .newest
                                  .includes(book: [:author,
                                                  {cover_attachment: :blob}])
                                  .map(&:book)
  end

  def valid_borrow_amount? selected_books
    is_book_present = selected_books.present?
    is_over_size = selected_books&.size.to_i > Settings.request.allow_amount
    return true if is_book_present && !is_over_size

    flash.now[:red] = t "error.cant_borrow_more_than",
                        allow_amount: Settings.request.allow_amount
    flash.now[:red] = t "error.less_than_a_book" unless is_book_present
    false
  end

  def has_unreturned_books?
    return unless current_user.borrow_requests.pending_or_overdue.any?

    handle_invalid t "error.has_unreturned_books"
  end

  def correct_user
    return if @request

    handle_invalid_destroy_or_handle t "error.cant_cancel_other_request"
  end

  def is_pending?
    return if @request.pending?

    handle_invalid_destroy_or_handle t "error.can_only_cancel_pending_request"
  end

  def validate_action_allowed
    allowed_statuses = Request::ALLOWED_ACTIONS[@request.status]
    return if allowed_statuses&.include? params[:status].to_sym

    handle_invalid_destroy_or_handle t "error.validate_status_allowed",
                                       current_status: @request.status,
                                       new_status: params[:status]
  end

  def has_out_of_stock_book?
    return unless @request.books.with_zero_in_stock.exists?

    handle_invalid_destroy_or_handle t "error.contain_out_of_stock_books"
  end

  def load_request_to_destroy
    @request = current_user.borrow_requests.find_by id: params[:id]
  end

  def load_request_to_handle
    @request = Request.includes(:books, :borrower).find_by(id: params[:id])
    return if @request

    handle_invalid_destroy t "error.request_not_found"
  end

  def build_book_params selected_books
    selected_books&.map{|book_id| {book_id:}}
  end

  def create_borrow_request selected_books
    request = current_user.borrow_requests
                          .create! start_date: request_params[:start_date],
                                   end_date: request_params[:end_date]
    request.requested_books.create!(build_book_params(selected_books))
  end

  def delete_selected_books selected_books
    current_user.selected_books.by_book_ids(selected_books).delete_all
  end

  def change_status
    @request.update!(status: params[:status], processor: current_user)
  end

  def change_book_amount amount
    @request.books.each do |book|
      book.update!(in_stock: book.in_stock + amount)
    end
  end

  def process_create_request selected_books
    ActiveRecord::Base.transaction do
      create_borrow_request selected_books
      delete_selected_books selected_books
    end
    handle_sucess t "success.request_created"
  rescue ActiveRecord::RecordInvalid => e
    handle_invalid e.record.errors.full_messages.join(", ")
  end

  def process_accept_or_return_request
    ActiveRecord::Base.transaction do
      change_status
      change_book_amount(params[:status] == "borrowing" ? -1 : 1)
    end
  rescue ActiveRecord::RecordInvalid => e
    handle_invalid e.record.errors.full_messages.join(", ")
  end

  def process_decline_request
    params[:note].present? && @request.update!(status: params[:status],
                                               note: params[:note])
  end

  def handle_invalid message
    flash.now[:red] = message
    load_selected_books
    render :new, status: :unprocessable_entity
  end

  def handle_sucess message
    flash[:emerald] = message
    redirect_to root_path, status: :see_other
  end

  def handle_invalid_destroy_or_handle message
    flash[:red] = message
    redirect_to request.referer || root_url
  end

  def handle_change_status_success
    if @request.borrower.email == Settings.demo_email
      UserMailer.request_status_changed(@request.borrower, params[:status])
                .deliver_now
    end
    flash[:emerald] = t "success.changed_status", new_status: params[:status]
    redirect_to all_requests_path, status: :see_other
  end
end
