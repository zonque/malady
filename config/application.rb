require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Malady
  # ENV-driven configuration helpers. Defined here — NOT in an initializer —
  # because config/environments/*.rb are processed BEFORE initializers and
  # reference these (e.g. production.rb reads Malady.smtp_settings / .mailer_host).
  # Putting them in an initializer caused "undefined method" at production boot.
  SIGNUP_TRUTHY = %w[true 1 yes on].freeze

  # Fail-closed: only explicit truthy values open signups (a typo stays closed).
  def self.signups_allowed?(env = ENV)
    SIGNUP_TRUTHY.include?(env.fetch("MALADY_ALLOW_SIGNUPS", "false").to_s.strip.downcase)
  end

  def self.mailer_sender(env = ENV)
    env.fetch("MALADY_MAILER_SENDER", "no-reply@malady.local")
  end

  def self.mailer_host(env = ENV)
    env.fetch("MALADY_HOST", "localhost")
  end

  def self.smtp_settings(env = ENV)
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

  def self.exception_recipients(env = ENV)
    env.fetch("MALADY_EXCEPTION_RECIPIENTS", "").split(",").map(&:strip).reject(&:blank?)
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.i18n.default_locale = :en
    config.i18n.available_locales = [ :en ]

    config.action_mailer.default_options = { from: Malady.mailer_sender }
  end
end
