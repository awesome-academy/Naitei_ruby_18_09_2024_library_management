class Request < ApplicationRecord
  belongs_to :borrower, class_name: User.name
  belongs_to :processor, class_name: User.name
  has_many :requested_books, dependent: :destroy
  has_many :books, through: :requested_books

  enum status: {pending: 0, declined: 1, borrowing: 2, returned: 3, overdue: 4}

  validates :status, inclusion: {in: statuses.keys}, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates_comparison_of :start_date, less_than: :end_date
  validate :must_have_more_than_one_book

  private

  def must_have_more_than_one_book
    return unless requested_books.size <= 1

    errors.add(:base, t("error.less_than_a_book"))
  end
end
