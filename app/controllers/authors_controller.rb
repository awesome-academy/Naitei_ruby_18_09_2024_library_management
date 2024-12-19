class AuthorsController < ApplicationController
  before_action :load_author

  def show; end

  private

  def load_author
    @author = Author.find_by id: params[:id]
    handle_invalid_author and return unless @author

    @pagy, @written_books = pagy @author.books.includes(:genre),
                                 limit: Settings.default_pagination
  end

  def handle_invalid_author
    flash[:red] = t "error.author_not_exist"
    redirect_to request.referer || root_path
  end
end
