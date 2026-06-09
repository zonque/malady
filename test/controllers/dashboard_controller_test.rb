require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redirects to sign in when logged out" do
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "shows my metrics ordered by position when logged in" do
    user = confirmed_user(email: "a@b.c")
    user.metrics.create!(name: "Second", data_type: "text", position: 2)
    user.metrics.create!(name: "First", data_type: "text", position: 1)
    sign_in user
    get root_path
    assert_response :success
    assert_operator response.body.index("First"), :<, response.body.index("Second")
  end

  test "shows reading count and last-recorded time per metric" do
    user = confirmed_user(email: "stats@m.test")
    m = user.metrics.create!(name: "Weight", data_type: "decimal", unit: "kg")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 2, 1, 8), value: "72")
    empty = user.metrics.create!(name: "Mood", data_type: "text")
    sign_in user
    get root_path
    assert_response :success
    assert_match "2 readings", response.body
    assert_match "No readings yet", response.body  # the metric with zero points
    # the latest recorded_at is rendered as a UTC iso8601 <time> for client-side local conversion
    assert_match "2026-02-01T08:00:00Z", response.body
  end

  test "reorder updates metric positions" do
    user = confirmed_user(email: "r@m.test")
    a = user.metrics.create!(name: "A", data_type: "text", position: 0)
    b = user.metrics.create!(name: "B", data_type: "text", position: 1)
    sign_in user
    patch metrics_positions_path, params: { order: [ b.id, a.id ] }
    assert_response :no_content
    assert_equal 0, b.reload.position
    assert_equal 1, a.reload.position
  end

  test "each metric card links to the metric" do
    user = confirmed_user(email: "click@m.test")
    m = user.metrics.create!(name: "Weight", data_type: "decimal")
    sign_in user
    get root_path
    assert_response :success
    assert_select "a[href=?]", metric_path(m)
  end

  test "header shows the signed-in user's email" do
    user = confirmed_user(email: "whoami@m.test")
    sign_in user
    get root_path
    assert_response :success
    assert_match "whoami@m.test", response.body
  end

  test "dashboard shows a sparkline chart for a numeric metric with data" do
    user = confirmed_user(email: "spark@m.test")
    m = user.metrics.create!(name: "Weight", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 2), value: "72")
    sign_in user
    get root_path
    assert_response :success
    assert_match "Chartkick", response.body
  end

  test "dashboard shows no chart for a text-only metric" do
    user = confirmed_user(email: "nospark@m.test")
    m = user.metrics.create!(name: "Note", data_type: "text")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "hi")
    sign_in user
    get root_path
    assert_response :success
    assert_no_match "Chartkick", response.body
  end
end
