class BooksController < ApplicationController
  include ApplicationHelper

  def index
    @pagy, @books = pagy Book.includes(:author, cover_attachment: :blob).all,
                         limit: Settings.default_pagination
    return if current_user.blank?

    @selected_book = current_user.selected_books.build
  end

  def show; end

  def new; end

  def create; end
end
