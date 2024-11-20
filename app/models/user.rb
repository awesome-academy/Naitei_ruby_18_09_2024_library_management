class User < ApplicationRecord
  PERMITTED_PARAMS ||= [:name, :email, :phone,
                        :password, :password_confirmation].freeze

  has_many :comments, dependent: :destroy
  has_many :borrowed_requests, class_name: Request.name,
            foreign_key: :borrower_id, dependent: :destroy
  has_many :processed_requests, class_name: Request.name,
            foreign_key: :processer_id, dependent: :nullify
  has_many :selected_books, dependent: :destroy
  has_many :favorites, dependent: :destroy

  has_secure_password

  attr_accessor :activation_token

  before_save :downcase_email
  before_create :create_activation_digest

  validates :name,
            presence: true,
            length: {maximum: Settings.username.max_length}

  validates :email,
            presence: true,
            length: {maximum: Settings.email.max_length},
            format: {with: Regexp.new(Settings.email.format,
                                      Regexp::IGNORECASE)},
            uniqueness: {case_sensitive: false}

  validates :phone,
            presence: true,
            length: {is: Settings.phone_length},
            uniqueness: true

  validates :password,
            presence: true,
            length: {minimum: Settings.password.min_length}

  class << self
    def new_token
      SecureRandom.urlsafe_base64
    end

    def digest string
      cost =
        if ActiveModel::SecurePassword.min_cost
          BCrypt::Engine::MIN_COST
        else
          BCrypt::Engine.cost
        end
      BCrypt::Password.create(string, cost:)
    end
  end

  def activate
    update_columns activated: true, activated_at: Time.zone.now
  end

  private

  def downcase_email
    email.downcase!
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
