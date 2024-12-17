class UserMailer < ApplicationMailer
  def request_status_changed user, status
    @user = user
    @status = status
    mail to: user.email, subject: t("mail.status_changed.title")
  end
end
