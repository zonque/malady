require "test_helper"

class MailerSettingsTest < ActiveSupport::TestCase
  test "smtp_settings reads ENV with sensible defaults" do
    env = {
      "MALADY_SMTP_ADDRESS" => "smtp.example.com",
      "MALADY_SMTP_PORT" => "2525",
      "MALADY_SMTP_USER_NAME" => "u",
      "MALADY_SMTP_PASSWORD" => "p",
      "MALADY_SMTP_DOMAIN" => "example.com",
      "MALADY_SMTP_AUTHENTICATION" => "login",
      "MALADY_SMTP_STARTTLS" => "false"
    }
    s = Malady.smtp_settings(env)
    assert_equal "smtp.example.com", s[:address]
    assert_equal 2525, s[:port]
    assert_equal "u", s[:user_name]
    assert_equal :login, s[:authentication]
    assert_equal false, s[:enable_starttls_auto]
  end

  test "smtp_settings defaults when ENV is empty" do
    s = Malady.smtp_settings({})
    assert_equal 587, s[:port]
    assert_equal :plain, s[:authentication]
    assert_equal true, s[:enable_starttls_auto]
  end

  test "mailer_sender falls back to default" do
    assert_equal "no-reply@malady.local", Malady.mailer_sender({})
    assert_equal "x@y.z", Malady.mailer_sender("MALADY_MAILER_SENDER" => "x@y.z")
  end
end
