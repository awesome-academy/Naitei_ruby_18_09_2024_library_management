class BooksController < ApplicationController
  def index
    @pagy, @books = pagy Book.all, limit: Settings.default_pagination
  end

  def show; end

  def new; end

  def create; end
end
