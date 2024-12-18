class BooksController < ApplicationController
  include ApplicationHelper

  before_action :load_book, on: :show

  def index
    @pagy, @books = pagy Book.includes(:author, cover_attachment: :blob).all,
                         limit: Settings.default_pagination
    return if current_user.blank?

    @selected_book = current_user.selected_books.build
  end

  def show
    @pagy, @comments = pagy Comment.includes(:user).by_book(params[:id]),
                            limit: Settings.default_pagination
    return if current_user.blank?

    @selected_book = current_user.selected_books.build
    @comment = current_user.comments.build
  end

  def new; end

  def create; end

  def search
    @pagy, @books = pagy Book.includes(:author, cover_attachment: :blob)
                             .search(params[:query],
                                     params[:search_type].to_sym),
                         limit: Settings.default_pagination
    @selected_book = current_user.selected_books.build if current_user.present?
    render :index
  end

  private

  def load_book
    @book = Book.find_by id: params[:id]
  end
end
