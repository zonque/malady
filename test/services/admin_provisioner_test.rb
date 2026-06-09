require "test_helper"

class AdminProvisionerTest < ActiveSupport::TestCase
  test "creates a confirmed admin from ENV" do
    env = { "MALADY_ADMIN_EMAIL" => "admin@malady.local", "MALADY_ADMIN_PASSWORD" => "supersecret1" }
    user = AdminProvisioner.new(env).call
    assert user.admin?
    assert user.persisted?
    assert user.confirmed?
    assert user.valid_password?("supersecret1")
  end

  test "updates password and re-grants admin if the account already exists" do
    User.create!(email: "admin@malady.local", password: "oldpassword1")
    env = { "MALADY_ADMIN_EMAIL" => "admin@malady.local", "MALADY_ADMIN_PASSWORD" => "newpassword1" }
    user = AdminProvisioner.new(env).call
    assert user.admin?
    assert user.valid_password?("newpassword1")
  end

  test "returns nil and does nothing when ENV is incomplete" do
    assert_nil AdminProvisioner.new({}).call
    assert_nil AdminProvisioner.new("MALADY_ADMIN_EMAIL" => "x@y.z").call
  end
end
