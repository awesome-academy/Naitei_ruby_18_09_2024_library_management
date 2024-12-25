class BooksController < ApplicationController
  load_resource

  def index
    @pagy, @books = pagy @books.includes(:author, cover_attachment: :blob).all,
                         limit: Settings.default_pagination
    return if current_user.blank?

    @selected_book = current_user.selected_books.build
  end

  def show
    @pagy, @comments = pagy Comment.includes(:user).by_book(@book.id),
                            limit: Settings.default_pagination
    return if current_user.blank?

    @selected_book = current_user.selected_books.build
    @comment = current_user.comments.build
  end

  def search
    @pagy, @books = pagy @books.includes(:author, cover_attachment: :blob)
                               .search(params[:query],
                                       params[:search_type].to_sym),
                         limit: Settings.default_pagination
    @selected_book = current_user.selected_books.build if current_user.present?
    render :index
  end

  rescue_from ActiveRecord::RecordNotFound do
    flash[:red] = t "error.book_not_found"
    redirect_to request.referer || root_path
  end
end
