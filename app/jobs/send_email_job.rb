class SendEmailJob < ApplicationJob
  queue_as :mailers

  def perform borrower_id, status
    borrower = User.find borrower_id
    UserMailer.request_status_changed(borrower, status).deliver_later
  end
end
