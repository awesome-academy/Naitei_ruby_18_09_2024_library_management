class BookIndexSerializer < ActiveModel::Serializer
  attributes :id, :name, :in_stock, :cover_url, :author_name

  def cover_url
    return unless object.cover.attached?

    Rails.application.routes.url_helpers.url_for object.cover
  end

  def author_name
    object.author.name
  end
end
