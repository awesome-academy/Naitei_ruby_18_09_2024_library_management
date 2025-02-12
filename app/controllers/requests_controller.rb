class RequestsController < ApplicationController
  include RequestsHelper

  authorize_resource

  before_action :load_selected_books, only: :new
  before_action :load_request_to_destroy, :is_pending?, only: :destroy
  before_action :load_request_to_handle, only: :handle
  rescue_from CanCan::AccessDenied, with: :handle_access_denied

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
    service = CreateRequestService.new current_user, request_params
    if service.call
      flash[:emerald] = t "success.request_created"
      redirect_to root_path, status: :see_other
    else
      flash.now[:red] = service.errors.join(", ")
      load_selected_books
      render :new, status: :unprocessable_entity
    end
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
    service = HandleRequestService.new current_user, @request,
                                       params[:status], params[:note]
    if service.call
      flash[:emerald] = t "success.changed_status", new_status: params[:status]
      redirect_to all_requests_path, status: :see_other
    else
      handle_invalid service.errors.join(", ")
    end
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

  def is_pending?
    return if @request.pending?

    handle_invalid t "error.can_only_cancel_pending_request"
  end

  def load_request_to_destroy
    @request = current_user.borrow_requests.find_by id: params[:id]
  end

  def load_request_to_handle
    @request = Request.includes(:books, :borrower).find_by(id: params[:id])
    return if @request

    handle_invalid t "error.request_not_found"
  end

  def handle_invalid message
    flash[:red] = message
    redirect_to request.referer || root_url
  end

  def handle_access_denied
    flash[:red] = t "error.not_logged_in"
    redirect_to new_user_session_path
  end
end
