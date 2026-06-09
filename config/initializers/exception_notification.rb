recipients = Malady.exception_recipients
if recipients.any?
  Rails.application.config.middleware.use ExceptionNotification::Rack,
    email: {
      email_prefix: "[Malady] ",
      sender_address: Malady.mailer_sender,
      exception_recipients: recipients
    }
end
