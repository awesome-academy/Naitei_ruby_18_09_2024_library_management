class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate(auth_options)
    if resource.nil?
      handle_fail_login
    else
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  protected

  def set_flash_message! key, kind, options = {}
    flash_type = key == :notice ? :emerald : :red
    flash[flash_type] = find_message(kind, options) if is_flashing_format?
  end

  private

  def handle_fail_login
    flash[:red] = t "error.wrong_credentials"
    self.resource = User.new(email: params[:user][:email])
    render :new, status: :unprocessable_entity
  end
end
