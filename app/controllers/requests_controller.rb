class RequestsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in?
  before_action :has_unreturned_books?, on: :create

  def new
    load_selected_books
    @request = Request.new
  end

  def create
    start_date = request_params[:start_date]
    end_date = request_params[:end_date]
    selected_books = request_params[:selected_books]&.map(&:to_i)

    unless valid_borrow_amount? selected_books
      load_selected_books
      render :new, status: :unprocessable_entity and return
    end

    process_request start_date, end_date, selected_books
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
    if selected_books.blank?
      flash.now[:red] = t "error.less_than_a_book"
    elsif selected_books.size > Settings.request.allow_amount
      flash.now[:red] = t "error.cant_borrow_more_than",
                          allow_amount: Settings.request.allow_amount
    else
      return true
    end

    false
  end

  def has_unreturned_books?
    return unless current_user.borrow_requests
                              .where(status: [:pending, :overdue]).any?

    flash.now[:red] = t "error.has_unreturned_books"
    handle_invalid_request
  end

  def create_borrow_request s_date, e_date, selected_books
    request = current_user.borrow_requests
                          .create!(start_date: s_date, end_date: e_date)
    request.requested_books.create!(build_book_params(selected_books))
  end

  def build_book_params selected_books
    selected_books&.map{|book_id| {book_id:}}
  end

  def delete_selected_books selected_books
    current_user.selected_books.where(book_id: selected_books).delete_all
  end

  def process_request s_date, e_date, selected_books
    ActiveRecord::Base.transaction do
      create_borrow_request(s_date, e_date, selected_books)
      delete_selected_books(selected_books)
    end
    handle_sucess_request
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:red] = e.record.errors.full_messages.join(", ")
    handle_invalid_request
  end

  def handle_invalid_request
    load_selected_books
    render :new, status: :unprocessable_entity
  end

  def handle_sucess_request
    flash[:emerald] = t "success.request_created"
    redirect_to root_path, status: :see_other
  end
end
