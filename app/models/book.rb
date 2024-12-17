class Book < ApplicationRecord
  belongs_to :author
  belongs_to :publisher
  belongs_to :genre

  has_many :comments, dependent: :destroy
  has_many :requests, through: :requested_books
  has_many :selected_books, dependent: :destroy
  has_many :requested_books, dependent: :destroy
  has_many :favorite_books, dependent: :destroy

  scope :with_zero_in_stock, ->{where(in_stock: 0)}

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
            numericality: {only_integer: true,
                           greater_than_or_equal_to: Settings.book.min_in_stock}
  validates :cover,
            content_type: {in: allow_image_type},
            size: {less_than: Settings.image.max_size.megabytes},
            allow_nil: true,
            if: :cover_attached?

  class << self
    def search query, search_type
      base_query = self
      conditions = build_conditions(query, search_type)
      base_query = apply_joins(base_query, search_type)
      base_query.where(conditions)
    end

    def build_conditions query, search_type
      case search_type
      when :name
        build_name_condition query
      when :author
        build_author_condition query
      when :genre
        build_genre_condition query
      when :publisher
        build_publisher_condition query
      when :all
        build_all_conditions query
      end
    end

    def apply_joins base_query, search_type
      case search_type
      when :all
        base_query = base_query.joins(:genre, :author, :publisher)
      when :genre
        base_query = base_query.joins(:genre)
      when :author
        base_query = base_query.joins(:author)
      when :publisher
        base_query = base_query.joins(:publisher)
      end
      base_query
    end

    def build_name_condition query
      Book.arel_table[:name].matches("#{query}%")
    end

    def build_author_condition query
      Author.arel_table[:name].matches("#{query}%")
    end

    def build_genre_condition query
      Genre.arel_table[:name].matches("#{query}%")
    end

    def build_publisher_condition query
      Publisher.arel_table[:name].matches("#{query}%")
    end

    def build_all_conditions query
      build_name_condition(query)
        .or(build_author_condition(query))
        .or(build_genre_condition(query))
        .or(build_publisher_condition(query))
    end
  end

  private

  def cover_attached?
    cover.attached?
  end
end
