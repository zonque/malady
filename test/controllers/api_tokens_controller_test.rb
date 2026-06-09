require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup { @user = confirmed_user(email: "a@b.c") }

  test "anonymous is redirected to sign in" do
    get api_token_path
    assert_redirected_to new_user_session_path
  end

  test "show displays the current token" do
    sign_in @user
    get api_token_path
    assert_response :success
    assert_match @user.api_token, response.body
  end

  test "update rotates the token" do
    sign_in @user
    old = @user.api_token
    patch api_token_path
    assert_redirected_to api_token_path
    assert_not_equal old, @user.reload.api_token
  end
end
