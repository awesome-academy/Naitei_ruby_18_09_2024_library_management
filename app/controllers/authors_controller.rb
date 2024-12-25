class AuthorsController < ApplicationController
  load_and_authorize_resource

  def show
    @pagy, @written_books = pagy @author.books.includes(:genre),
                                 limit: Settings.default_pagination
  end

  rescue_from ActiveRecord::RecordNotFound do
    flash[:red] = t "error.author_not_exist"
    redirect_to request.referer || root_path
  end

  rescue_from CanCan::AccessDenied do
    flash[:red] = t "error.not_logged_in"
    redirect_to new_user_session_path
  end
end
