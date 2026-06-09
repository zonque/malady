require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "a@b.c")
    @metric = @user.metrics.create!(name: "Weight", data_type: "decimal", unit: "kg")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "72.5")
    sign_in @user
  end

  test "json export contains metrics and data points" do
    get json_export_path(format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Weight", body["metrics"].first["name"]
    assert_equal "72.5", body["metrics"].first["data_points"].first["value_text"]
    assert_equal "2026-01-01T08:00:00Z", body["metrics"].first["data_points"].first["recorded_at"]
  end

  test "csv export is long-format with one row per data point" do
    get csv_export_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    lines = response.body.strip.split("\n")
    assert_equal "metric_slug,metric_name,recorded_at,value,unit,note", lines.first
    assert_match "weight,Weight,2026-01-01T08:00:00Z,72.5,kg,", lines[1]
  end
end
