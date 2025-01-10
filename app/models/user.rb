class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :rememberable,
         :validatable, :lockable

  PERMITTED_PARAMS ||= [:name, :email, :phone,
                        :password, :password_confirmation].freeze

  has_many :comments, dependent: :destroy
  has_many :borrow_requests, class_name: Request.name,
            foreign_key: :borrower_id, dependent: :destroy
  has_many :processed_requests, class_name: Request.name,
            foreign_key: :processor_id, dependent: :nullify
  has_many :selected_books, dependent: :destroy
  has_many :carted_books, through: :selected_books, source: :book
  has_many :favorite_books, dependent: :destroy
  has_many :favorited_books, through: :favorite_books, source: :book

  before_save :downcase_email

  validates :name,
            presence: true,
            length: {maximum: Settings.username.max_length}

  validates :phone,
            presence: true,
            length: {is: Settings.phone_length},
            uniqueness: true

  def activate
    update_columns activated: true, activated_at: Time.zone.now
  end

  private

  def downcase_email
    email.downcase!
  end
end
