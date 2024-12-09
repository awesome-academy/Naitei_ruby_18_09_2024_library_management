class SelectedBook < ApplicationRecord
  PERMITTED_PARAMS = [:book_id].freeze

  belongs_to :user
  belongs_to :book

  scope :newest, ->{order created_at: :desc}
end
