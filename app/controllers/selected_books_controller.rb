class SelectedBooksController < ApplicationController
  include ApplicationHelper

  before_action :require_login
  before_action :correct_user, only: :destroy

  def create
    @selected_book = current_user.selected_books.build selected_book_params

    begin
      if @selected_book.save
        handle_sucess
      else
        handle_fail
      end
    rescue StandardError
      flash[:red] = t "error.already_in_cart",
                      book_name: @selected_book.book.name
      redirect_to request.referer || root_url, status: :see_other
    end
  end

  def destroy
    unless @selected_book.destroy
      flash[:red] = t "cant_delete_selected_book"
      render :new, status: :unprocessable_entity
    end
    redirect_to request.referer || root_url
  end

  private

  def selected_book_params
    params.require(:selected_book).permit(SelectedBook::PERMITTED_PARAMS)
  end

  def correct_user
    @selected_book = current_user.selected_books.find_by(book_id: params[:id])
    return if @selected_book

    flash[:red] = t "error.not_your_book"
    redirect_to request.referer || root_url
  end

  def handle_sucess
    flash[:emerald] = t "view.book.added_to_cart",
                        book_name: @selected_book.book.name
    redirect_to request.referer || root_url
  end

  def handle_fail
    flash.now[:red] = t "error.cant_add_to_cart",
                        book_name: @selected_book.book.name
    render root_path, status: :unprocessable_entity
  end
end
