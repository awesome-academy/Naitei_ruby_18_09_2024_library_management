require "active_support/core_ext/integer/time"

Rails.application.configure do
  Rails.application.routes.default_url_options[:host] = "localhost:3000"
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.active_storage.service = :local

  host = "localhost:3000"
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {host: host}

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: ENV["mailtrap_username"],
    password: ENV["mailtrap_password"],
    address: ENV["mailtrap_address"],
    host: ENV["mailtrap_host"],
    port: ENV["mailtrap_port"],
    authentication: :login
  }

  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.assets.quiet = true
  config.web_console.permissions = "172.18.0.0/16"
  config.active_job.queue_adapter = :sidekiq
end
