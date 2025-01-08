Devise.setup do |config|
  require "devise/orm/active_record"
  config.mailer_sender = Settings.default_email
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? Settings.devise.stretch.test : Settings.devise.stretch.other
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = Settings.devise.password.min_length..Settings.devise.password.max_length
  config.email_regexp = Regexp.new(Settings.email.format, Regexp::IGNORECASE)
  config.lock_strategy = :failed_attempts
  config.unlock_keys = [:email]
  config.unlock_strategy = :both
  config.maximum_attempts = Settings.devise.max_attempts
  config.unlock_in = Settings.devise.unlock_in.hour
  config.last_attempt_warning = true
  config.reset_password_within = Settings.devise.reset_password_within.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
