class RequestsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in?

  def new
    @selected_books = current_user.selected_books
                                  .newest
                                  .includes(book: [:author,
                                                   {cover_attachment: :blob}])
                                  .map(&:book)
  end

  def create; end
end
