class Book < ApplicationRecord
  PERMITTED_PARAMS = [:name, :description, :in_stock, :borrowable,
                     :author_id, :publisher_id, :genre_id, :cover].freeze

  belongs_to :author
  belongs_to :publisher
  belongs_to :genre

  has_many :comments, dependent: :destroy
  has_many :requests, through: :requested_books
  has_many :selected_books, dependent: :destroy
  has_many :requested_books, dependent: :destroy
  has_many :favorite_books, dependent: :destroy

  ransack_alias :book_search, :name_or_description

  ransacker :can_borrow do
    Arel.sql("(in_stock > 0 AND borrowable = true)")
  end

  ransacker :created_date, type: :date do
    Arel.sql("DATE(created_at)")
  end

  scope :with_zero_in_stock, ->{where(in_stock: 0)}

  has_one_attached :cover do |attachable|
    attachable.variant :display,
                       resize_to_limit: Settings.image.max_size
  end

  allow_image_type = Settings.image.allow_type.split(", ")

  validates :name,
            presence: true,
            length: {maximum: Settings.book.name.max_length}
  validates :description,
            presence: true,
            length: {maximum: Settings.book.description.max_length}
  validates :in_stock,
            presence: true,
            numericality: {only_integer: true,
                           greater_than_or_equal_to: Settings.book.min_in_stock}
  validates :cover,
            content_type: {in: allow_image_type},
            size: {less_than: Settings.image.max_size.megabytes},
            allow_nil: true,
            if: :cover_attached?

  class << self
    def ransackable_attributes auth_object = nil
      if auth_object == :guest
        %w(name description book_search in_stock
           author_id publisher_id genre_id)
      elsif auth_object == :user
        %w(name description book_search in_stock
           author_id publisher_id genre_id borrowable can_borrow)
      else
        %w(name description book_search in_stock author_id
           publisher_id genre_id borrowable can_borrow created_date)
      end
    end

    def ransackable_associations _auth_object = nil
      %w(author publisher genre)
    end
  end

  private

  def cover_attached?
    cover.attached?
  end
end
