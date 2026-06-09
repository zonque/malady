require "test_helper"

class MetricsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "a@b.c")
    @other = confirmed_user(email: "x@y.z")
    sign_in @user
  end

  test "index lists only my metrics" do
    mine = @user.metrics.create!(name: "Weight", data_type: "decimal")
    theirs = @other.metrics.create!(name: "Secret", data_type: "decimal")
    get metrics_path
    assert_response :success
    assert_match "Weight", response.body
    assert_no_match "Secret", response.body
  end

  test "create makes a metric for the current user" do
    assert_difference -> { @user.metrics.count }, 1 do
      post metrics_path, params: { metric: { name: "Heart Rate", data_type: "integer", unit: "bpm" } }
    end
    assert_redirected_to metric_path(@user.metrics.order(:created_at).last)
  end

  test "cannot access another user's metric" do
    theirs = @other.metrics.create!(name: "Secret", data_type: "decimal")
    get metric_path(theirs)
    assert_response :not_found
  end

  test "enumeration metric show renders a dropdown for logging values" do
    m = @user.metrics.create!(name: "Mood", data_type: "enumeration", enum_options: ["low", "high"])
    get metric_path(m)
    assert_response :success
    assert_select "select[name=?]", "data_point[value]"
    assert_select "option", text: "low"
  end

  test "metric show has a back link to the dashboard" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    get metric_path(m)
    assert_response :success
    assert_select "a[href=?]", root_path
  end

  test "show paginates data points to 10 per page" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    15.times { |i| m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 0, i), value: i.to_s) }
    get metric_path(m)
    assert_response :success
    assert_select "#data_points li", count: 10
  end

  test "show second page shows the remaining data points" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    15.times { |i| m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 0, i), value: i.to_s) }
    get metric_path(m, page: 2)
    assert_response :success
    assert_select "#data_points li", count: 5
  end

  test "show has pagination controls when more than 10 readings" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    12.times { |i| m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 0, i), value: i.to_s) }
    get metric_path(m)
    assert_response :success
    assert_match "Older", response.body
  end

  test "show without enough data points has no pagination controls" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    3.times { |i| m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 0, i), value: i.to_s) }
    get metric_path(m)
    assert_response :success
    assert_no_match "Older", response.body
  end

  test "numeric metric show renders a chart" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    get metric_path(m)
    assert_response :success
    assert_match "Chartkick", response.body
  end

  test "text metric show renders no chart" do
    m = @user.metrics.create!(name: "Note", data_type: "text")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "hello")
    get metric_path(m)
    assert_response :success
    assert_no_match "Chartkick", response.body
  end
end
