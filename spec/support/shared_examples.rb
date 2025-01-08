RSpec.shared_examples "guest user redirection" do
  it "redirects to the login page" do
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:red]).to eq(I18n.t("error.not_logged_in"))
  end
end

RSpec.shared_examples "when authenticated as user" do
  it "returns a 401 unauthorized error" do
    expect(response).to have_http_status(:unauthorized)
    expect(json_response["error"]).to eq(I18n.t("error.not_authorized"))
  end
end

RSpec.shared_examples "when provided with invalid token" do
  it "returns a 401 unauthorized error" do
    expect(response).to have_http_status(:unauthorized)
    expect(json_response["error"]).to eq(I18n.t("error.invalid_token"))
  end
end

RSpec.shared_examples "when token has expired" do
  it "returns a 401 unauthorized error" do
    expect(response).to have_http_status(:unauthorized)
    expect(json_response["error"]).to eq(I18n.t("error.expired_token"))
  end
end
