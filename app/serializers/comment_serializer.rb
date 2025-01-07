class CommentSerializer < ActiveModel::Serializer
  attributes :id, :content, :poster, :created_at

  def poster
    object.user.name
  end
end
