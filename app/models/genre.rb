class Genre < ApplicationRecord
  has_many :books, dependent: :destroy

  validates :name,
            presence: true,
            length: {maximum: Settings.author.max_length}
end
