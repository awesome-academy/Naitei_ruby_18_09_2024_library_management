class SessionsController < ApplicationController
  include SessionsHelper

  def new; end

  def create
    user = User.find_by email: params.dig(:session, :email)&.downcase
    if user&.authenticate params.dig(:session, :password)
      handle_success(user)
    else
      handle_fail
    end
  end

  def destroy
    log_out
    redirect_to login_path, status: :see_other
  end

  private

  def handle_success user
    log_in user
    flash[:emerald] = t "success.login"
    redirect_to root_path, status: :see_other
  end

  def handle_fail
    flash.now[:red] = t "error.wrong_credentials"
    render :new, status: :unprocessable_entity
  end
end
