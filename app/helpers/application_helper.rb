module ApplicationHelper
  include Pagy::Frontend

  def full_title page_title
    base_title = t "app_name"
    page_title.blank? ? base_title : "#{page_title} | #{base_title}"
  end

  def search_type_options
    [
      [t("header.search.dropdown.all"), "all"],
      [t("header.search.dropdown.name"), "name"],
      [t("header.search.dropdown.author"), "author"],
      [t("header.search.dropdown.genre"), "genre"],
      [t("header.search.dropdown.publisher"), "publisher"]
    ]
  end

  def require_login
    return if user_signed_in?

    flash[:red] = t "error.not_logged_in"
    redirect_to new_user_session_path
    false
  end
end
