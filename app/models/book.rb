class Book < ApplicationRecord
  belongs_to :author
  belongs_to :publisher
  belongs_to :genre

  has_many :comments, dependent: :destroy
  has_many :requests, through: :requested_books
  has_many :selected_books, dependent: :destroy
  has_many :requested_books, dependent: :destroy
  has_many :favorite_books, dependent: :destroy

  has_one_attached :cover do |attachable|
    attachable.variant :display,
                       resize_to_limit: Settings.image.max_size
  end

  allow_image_type = Settings.image.allow_type.split(", ")

  validates :name,
            presence: true,
            length: {maximum: Settings.book.name.max_length}
  validates :in_stock,
            presence: true,
            length: {minium: Settings.book.min_in_stock}
  validates :cover,
            content_type: {in: allow_image_type},
            size: {less_than: Settings.image.maxSize.megabytes},
            allow_nil: true
end
