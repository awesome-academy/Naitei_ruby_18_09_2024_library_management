class Author < ApplicationRecord
  has_many :books, dependent: :destroy

  class << self
    def ransackable_attributes _auth_object = nil
      %w(name)
    end

    def ransackable_associations _auth_object = nil
      %w(books)
    end
  end

  validates :name,
            presence: true,
            length: {maximum: Settings.author.max_length}
end
