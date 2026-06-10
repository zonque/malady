require "test_helper"

class OverviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "o@m.test")
    @m = @user.metrics.create!(name: "Weight", data_type: "decimal", unit: "kg")
    @m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    @m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 9), value: "80")
    sign_in @user
  end

  test "requires auth" do
    sign_out @user
    get overview_path
    assert_redirected_to new_user_session_path
  end

  test "renders metric, a reading value, and avg" do
    get overview_path(period: "day")
    assert_response :success
    assert_match "Weight", response.body
    assert_match "80", response.body   # a data point value
    assert_match "75", response.body   # avg of 70 and 80
  end

  test "accepts week and month periods" do
    get overview_path(period: "week"); assert_response :success
    get overview_path(period: "month"); assert_response :success
  end

  test "shows pagination across more than 10 buckets" do
    12.times { |i| @m.data_points.create!(recorded_at: Time.utc(2026, 3, 1 + i, 8), value: "70") }
    get overview_path(period: "day")
    assert_response :success
    assert_match "Older", response.body
    get overview_path(period: "day", page: 2)
    assert_response :success
  end

  test "only the current user's metrics" do
    other = confirmed_user(email: "x@m.test")
    other.metrics.create!(name: "Secret", data_type: "decimal")
    get overview_path
    assert_no_match "Secret", response.body
  end

  test "renders a section chart canvas for chartable data" do
    get overview_path(period: "day")
    assert_response :success
    assert_select "canvas[data-controller=?]", "overview-chart"
  end

  test "accepts a metrics filter param without error" do
    get overview_path(period: "day", metrics: [ @m.slug ])
    assert_response :success
  end

  test "ignore_time metric hides the time on overview points" do
    ti = @user.metrics.create!(name: "Episode", data_type: "boolean", ignore_time: true)
    travel_to Time.utc(2026, 1, 1, 14, 37) do
      ti.data_points.create!(recorded_at: "2026-01-01", value: "true")
    end
    get overview_path(period: "day", metrics: [ ti.slug ])
    assert_response :success
    assert_match "Episode", response.body  # the entry is rendered...
    assert_no_match "14:37", response.body # ...but its time is hidden
  end
end
