class Request < ApplicationRecord
  PERMITTED_PARAMS = [:start_date, :end_date, {selected_books: []}].freeze

  belongs_to :borrower, class_name: User.name
  belongs_to :processor, class_name: User.name, optional: true
  has_many :requested_books, dependent: :destroy
  has_many :books, through: :requested_books

  scope :pending_or_overdue, ->{where(status: [:pending, :overdue])}

  enum status: {pending: 0, declined: 1, borrowing: 2, returned: 3, overdue: 4}

  validates :status, inclusion: {in: statuses.keys}, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :start_date_must_not_be_in_the_past,
           :borrow_time_must_be_less_than_a_month,
           :start_date_must_be_before_end_date

  private

  def start_date_must_not_be_in_the_past
    return if start_date.blank? || start_date >= Time.zone.today

    errors.add(:base, I18n.t("error.past_start_date"))
  end

  def borrow_time_must_be_less_than_a_month
    return if end_date.blank? ||
              start_date.blank? ||
              (end_date - start_date).to_i <= Settings.request.max_borrow_days

    errors.add(:base, I18n.t("error.borrow_more_than_a_month"))
  end

  def start_date_must_be_before_end_date
    return if end_date.blank? ||
              start_date.blank? ||
              (end_date - start_date).to_i.positive?

    errors.add(:base, I18n.t("error.start_date_after_end_date"))
  end
end
