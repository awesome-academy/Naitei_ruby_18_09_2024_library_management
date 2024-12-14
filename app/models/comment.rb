class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :book

  scope :by_book, ->(id){where(book_id: id).order(created_at: :desc)}

  validates :content,
            presence: true,
            length: {maximum: Settings.comment.max_length}
end
