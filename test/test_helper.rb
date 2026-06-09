ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

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
