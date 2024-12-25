class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: :create
  before_action :configure_account_update_params, only: :update

  # rubocop:disable Lint/UselessMethodDefinition
  def create
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  def update
    if resource.update_with_password(account_update_params)
      set_flash_message!(:notice, :updated)
      redirect_to root_path, status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: User::PERMITTED_PARAMS)
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: User::PERMITTED_PARAMS)
  end

  def set_flash_message! key, kind, options = {}
    flash_type = key == :notice ? :emerald : :red
    flash[flash_type] = find_message(kind, options) if is_flashing_format?
  end
end
