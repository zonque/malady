require "test_helper"

class TimezonesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { @user = confirmed_user(email: "tz@m.test"); sign_in @user }

  test "updates the user's timezone when valid" do
    patch timezone_path, params: { time_zone: "America/New_York" }
    assert_response :success
    assert_equal "America/New_York", @user.reload.time_zone
  end

  test "rejects an invalid timezone" do
    patch timezone_path, params: { time_zone: "Not/AZone" }
    assert_response :unprocessable_entity
    assert_equal "UTC", @user.reload.time_zone
  end

  test "requires auth" do
    sign_out @user
    patch timezone_path, params: { time_zone: "America/New_York" }
    assert_redirected_to new_user_session_path
  end
end
