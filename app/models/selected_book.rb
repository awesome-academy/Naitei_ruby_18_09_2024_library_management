class SelectedBook < ApplicationRecord
  PERMITTED_PARAMS = [:book_id].freeze

  belongs_to :user
  belongs_to :book

  scope :newest, ->{order created_at: :desc}
  scope :by_book_ids, ->(ids){where(book_id: ids)}
end
