require "test_helper"

class MetricTypesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "a@b.c")
    @metric = @user.metrics.create!(name: "Reading", data_type: "text")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "10")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 2), value: "bad")
    sign_in @user
  end

  test "edit shows a dry-run preview for a target type" do
    get edit_metric_metric_type_path(@metric, target_type: "decimal")
    assert_response :success
    assert_match "1", response.body # one failing value reported
    assert_match "bad", response.body # sample failure shown
  end

  test "update applies the type change" do
    patch metric_metric_type_path(@metric), params: { target_type: "decimal" }
    assert_redirected_to metric_path(@metric)
    assert_equal "decimal", @metric.reload.data_type
    assert_equal 10.0, @metric.data_points.find_by(recorded_at: Time.utc(2026, 1, 1)).value_decimal
  end
end
