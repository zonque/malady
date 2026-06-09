require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = confirmed_user(email: "admin@m.test", admin: true)
    @member = confirmed_user(email: "member@m.test")
  end

  test "non-admin is denied" do
    sign_in @member
    get admin_users_path
    assert_response :not_found
  end

  test "admin can list users" do
    sign_in @admin
    get admin_users_path
    assert_response :success
    assert_match "member@m.test", response.body
  end

  test "admin can lock and unlock a user" do
    sign_in @admin
    post lock_admin_user_path(@member)
    assert @member.reload.access_locked?
    post unlock_admin_user_path(@member)
    assert_not @member.reload.access_locked?
  end

  test "admin can confirm a user" do
    @member.update!(confirmed_at: nil)
    sign_in @admin
    post confirm_admin_user_path(@member)
    assert @member.reload.confirmed?
  end

  test "admin can delete a user" do
    sign_in @admin
    assert_difference -> { User.count }, -1 do
      delete admin_user_path(@member)
    end
  end

  test "anonymous is redirected to sign in" do
    get admin_users_path
    assert_redirected_to new_user_session_path
  end

  test "admin cannot delete or lock their own account" do
    sign_in @admin
    assert_no_difference -> { User.count } do
      delete admin_user_path(@admin)
    end
    assert_response :not_found
  end
end
