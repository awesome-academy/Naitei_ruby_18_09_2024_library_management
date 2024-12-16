module CommentsHelper
  def can_delete_comment? comment
    current_user.is_admin || comment.user == current_user
  end

  def commenter_name comment
    comment.user == current_user ? t("text.you") : comment.user.name
  end
end
