class UsersController < ApplicationController
  load_resource

  def show; end

  rescue_from ActiveRecord::RecordNotFound do
    flash[:red] = t "error.user_not_exist"
    redirect_to request.referer || root_path
  end
end
