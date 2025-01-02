RSpec.shared_examples "guest user redirection" do
  it "redirects to the login page" do
    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:red]).to eq(I18n.t("error.not_logged_in"))
  end
end
