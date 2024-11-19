class User < ApplicationRecord
  has_many :comments, dependent: :destroy
  has_many :borrowed_requests, class_name: Request.name,
            foreign_key: :borrower_id, dependent: :destroy
  has_many :processed_requests, class_name: Request.name,
            foreign_key: :processer_id, dependent: :nullify
  has_many :selected_books, dependent: :destroy
  has_many :favorites, dependent: :destroy

  validates :name,
            presence: true,
            length: {maximum: Settings.userName.max_length}

  validates :email,
            presence: true,
            length: {maximum: Settings.email.max_length},
            format: {with: Regexp.new(Settings.email.format,
                                      Regexp::IGNORECAE)},
            uniqueness: {case_sensitive: false}

  validates :password,
            presence: true,
            length: {minimum: Settings.password.min_length}
end
