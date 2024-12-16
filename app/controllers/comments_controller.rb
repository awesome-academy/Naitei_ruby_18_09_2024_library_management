class CommentsController < ApplicationController
  include ApplicationHelper

  before_action :logged_in?, :load_book
  before_action :load_comment, only: :destroy

  def create
    @comment = current_user.comments.build comment_params
    unless @comment.save
      flash.now[:red] = @comment.errors.full_messages.to_sentence
    end
    reload_with_turbo
  end

  def destroy
    if @comment.destroy
      flash.now[:emerald] = t "success.comment_deleted"
    else
      flash.now[:red] = t "error.cant_delete_comment"
    end
    reload_with_turbo
  end

  private

  def comment_params
    params.require(:comment).permit(Comment::PERMITTED_PARAMS)
  end

  def load_book
    @book = Book.find_by id: params.dig(:comment, :book_id) || params[:book_id]
    return if @book

    flash[:red] = t "error.book_not_found"
    redirect_to request.referer || root_path
  end

  def load_comment
    @comment = current_user.comments.find_by id: params[:id]
    return if @comment

    flash[:red] = t "error.not_your_comment"
    redirect_to request.referer || root_path
  end

  def reload_with_turbo
    respond_to do |format|
      format.html{redirect_to @book}
      format.turbo_stream do
        @pagy, @comments = pagy Comment.includes(:user).by_book(@book.id),
                                limit: Settings.default_pagination
        @comment = Comment.new
      end
    end
  end
end
