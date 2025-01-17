class Author < ApplicationRecord
  after_commit :reindex_books

  has_many :books, dependent: :destroy

  validates :name,
            presence: true,
            length: {maximum: Settings.author.max_length}

  class << self
    def ransackable_attributes _auth_object = nil
      %w(name)
    end

    def ransackable_associations _auth_object = nil
      %w(books)
    end
  end

  private

  def reindex_books
    books.each(&:touch)
  end
end
