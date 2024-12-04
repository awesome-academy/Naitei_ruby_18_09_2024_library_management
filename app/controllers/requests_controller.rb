class RequestsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in?

  def new
    @selected_books = current_user.selected_books.map(&:book)
  end

  def create; end
end
