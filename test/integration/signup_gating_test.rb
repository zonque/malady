require "test_helper"

class SignupGatingTest < ActionDispatch::IntegrationTest
  test "registration route is reachable when signups allowed" do
    with_signups(true) do
      get new_user_registration_path
      assert_response :success
    end
  end

  test "registration route is blocked when signups disallowed" do
    with_signups(false) do
      get new_user_registration_path
      assert_response :not_found
    end
  end

  test "POST registration (create) is also blocked when signups disallowed" do
    with_signups(false) do
      post user_registration_path, params: { user: { email: "x@y.z", password: "password123" } }
      assert_response :not_found
    end
  end

  test "sign-in page shows the sign-up link only when signups are allowed" do
    with_signups(true) do
      get new_user_session_path
      assert_match "Sign up", response.body
    end
    with_signups(false) do
      get new_user_session_path
      assert_no_match "Sign up", response.body
    end
  end

  private

  def with_signups(allowed)
    original = Malady.method(:signups_allowed?)
    Malady.define_singleton_method(:signups_allowed?) { allowed }
    yield
  ensure
    Malady.define_singleton_method(:signups_allowed?, original)
  end
end
