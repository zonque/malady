ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Guarantee the Tailwind build exists before any view-rendering test resolves it
# via stylesheet_link_tag. The compiled stylesheet is a gitignored artifact, and
# `bin/rails test` doesn't trigger tailwindcss-rails' build hook, so build it once
# here if missing. This is invocation- and CI-independent (works for bin/rails
# test, bundle exec rails test, and any pipeline). The CI "Build Tailwind CSS"
# step and bin/setup also build it; this is the safety net.
tailwind_build = Rails.root.join("app/assets/builds/tailwind.css")
unless tailwind_build.exist?
  require "tailwindcss/ruby"
  system(
    Tailwindcss::Ruby.executable.to_s,
    "-i", Rails.root.join("app/assets/tailwind/application.css").to_s,
    "-o", tailwind_build.to_s,
    "--minify",
    exception: true
  )
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Devise :confirmable blocks unconfirmed users from authenticating, so any
    # test that signs a user in must use a CONFIRMED user.
    def confirmed_user(email: "user@example.com", password: "password123", **attrs)
      User.create!(email:, password:, confirmed_at: Time.current, **attrs)
    end

    # Add more helper methods to be used by all tests here...
  end
end
