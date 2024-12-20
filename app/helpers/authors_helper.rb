module AuthorsHelper
  def biography author
    author.biography.presence || t("view.author.no_bio")
  end

  def birthday author
    author.birthday&.strftime("%B %d, %Y") || t("view.author.no_birthday")
  end
end
