class UsersController < ApplicationController
  def show
    @user = User.find_by id: params[:id]
    return if @user

    flash[:red] = t "error.not_logged_in"
    redirect_to root_path
  end
end
