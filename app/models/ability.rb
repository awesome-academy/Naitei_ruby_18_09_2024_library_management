class Ability
  include CanCan::Ability

  def initialize user
    can [:read, :search], Book
    can :read, Comment
    can :show, User
    return if user.blank?

    can :create, Comment
    can :destroy, Comment, user_id: user.id
    can [:read, :create], Request
    can :destroy, Request, user_id: user.id
    can :create, SelectedBook
    can :destroy, SelectedBook, user_id: user.id
    can :show, Author
    return unless user.is_admin?

    can :manage, :all
    cannot :destroy, SelectedBook
    can :destroy, SelectedBook, user_id: user.id
  end
end
