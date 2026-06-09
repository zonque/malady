module Malady
  module_function

  def mailer_sender(env = ENV)
    env.fetch("MALADY_MAILER_SENDER", "no-reply@malady.local")
  end

  def mailer_host(env = ENV)
    env.fetch("MALADY_HOST", "localhost")
  end

  def smtp_settings(env = ENV)
    {
      address: env.fetch("MALADY_SMTP_ADDRESS", "localhost"),
      port: env.fetch("MALADY_SMTP_PORT", "587").to_i,
      user_name: env["MALADY_SMTP_USER_NAME"],
      password: env["MALADY_SMTP_PASSWORD"],
      domain: env.fetch("MALADY_SMTP_DOMAIN", "localhost"),
      authentication: env.fetch("MALADY_SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: env.fetch("MALADY_SMTP_STARTTLS", "true") == "true"
    }
  end

  def exception_recipients(env = ENV)
    env.fetch("MALADY_EXCEPTION_RECIPIENTS", "").split(",").map(&:strip).reject(&:blank?)
  end
end

Rails.application.configure do
  config.action_mailer.default_options = { from: Malady.mailer_sender }
end
