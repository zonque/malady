require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "sends a report-only CSP header, not an enforcing one" do
    get new_user_session_path
    assert_nil response.headers["Content-Security-Policy"], "should not enforce yet (warn-only)"
    csp = response.headers["Content-Security-Policy-Report-Only"]
    assert csp.present?, "expected a report-only CSP header"
    assert_includes csp, "default-src 'self'"
    assert_includes csp, "object-src 'none'"
    assert_includes csp, "frame-ancestors 'none'"
    assert_includes csp, "style-src 'self' 'unsafe-inline'"
  end

  test "script-src is nonce-based with no unsafe-inline" do
    get new_user_session_path
    csp = response.headers["Content-Security-Policy-Report-Only"]
    assert_match(/script-src 'self' 'nonce-[^']+'/, csp)
    script_directive = csp.split(";").find { |d| d.strip.start_with?("script-src") }
    assert_not_includes script_directive, "unsafe-inline"
  end

  test "the importmap inline script carries the nonce" do
    user = confirmed_user(email: "csp@h.test")
    sign_in user
    get root_path
    assert_response :success
    assert_match(/<script[^>]+type="importmap"[^>]+nonce="[^"]+"/, response.body)
  end
end
