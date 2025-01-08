class Api::V1::SessionsController < Devise::SessionsController
  require Rails.root.join("lib/json_web_token")

  skip_before_action :verify_authenticity_token, only: %i(create destroy)

  def create
    self.resource = warden.authenticate
    if resource.nil?
      render json: {error: t("error.wrong_credentials")}, status: :unauthorized
    else
      render json: {
        message: t("success.login"),
        token: JsonWebToken.encode(id: resource.id),
        user: resource
      }, status: :ok
    end
  end

  # rubocop:disable Lint/UselessMethodDefinition
  def destroy
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  private

  def respond_to_on_destroy
    render json: {message: t("success.logout")}, status: :ok
  end
end
