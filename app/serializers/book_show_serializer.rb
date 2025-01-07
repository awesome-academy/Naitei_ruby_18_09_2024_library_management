class BookShowSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :borrowable, :cover_url,
             :author_name, :publisher_name, :genre_name

  has_many :comments, serializer: CommentSerializer

  def cover_url
    return unless object.cover.attached?

    Rails.application.routes.url_helpers.url_for object.cover
  end

  def author_name
    object.author.name
  end

  def publisher_name
    object.publisher.name
  end

  def genre_name
    object.genre.name
  end
end
