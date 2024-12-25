class CommentsController < ApplicationController
  load_and_authorize_resource

  before_action :load_book

  def create
    @comment.user_id = current_user.id
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

  rescue_from ActiveRecord::RecordNotFound do
    flash[:red] = t "error.comment_not_found"
    redirect_to request.referer || root_path
  end

  rescue_from CanCan::AccessDenied do
    flash[:red] = t "error.not_logged_in"
    redirect_to new_user_session_path
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
