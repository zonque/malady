require "test_helper"

class UserTokenTest < ActiveSupport::TestCase
  test "api_token is generated on create" do
    user = User.create!(email: "a@b.c", password: "password123")
    assert user.api_token.present?
  end

  test "rotate_api_token! changes the token" do
    user = User.create!(email: "a@b.c", password: "password123")
    old = user.api_token
    user.rotate_api_token!
    assert_not_equal old, user.api_token
  end
end
