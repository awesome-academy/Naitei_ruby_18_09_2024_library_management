class BooksController < ApplicationController
  include BooksHelper

  load_resource

  def index
    @q = Book.ransack(search_params, auth_object: user_role)
    @q.sorts = "name asc" if @q.sorts.empty?
    @pagy, @books = pagy @q.result
                           .includes(:author, cover_attachment: :blob),
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

  rescue_from ActiveRecord::RecordNotFound do
    flash[:red] = t "error.book_not_found"
    redirect_to request.referer || root_path
  end

  private

  def search_params
    update_in_stock_option if contain_in_stock_option?
    apply_or_query
  end

  def update_in_stock_option
    in_stock_option = "in_stock_#{params[:q][:amount_operator]}".to_sym
    params[:q][in_stock_option] = params[:q][:in_stock]
  end

  def apply_or_query
    is_or_query? ? params[:q].try(:merge, m: "or") : params[:q]
  end

  def contain_in_stock_option?
    params.dig(:q, :amount_operator) && params.dig(:q, :in_stock)
  end
end
