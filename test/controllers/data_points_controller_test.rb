require "test_helper"

class DataPointsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = confirmed_user(email: "a@b.c")
    @metric = @user.metrics.create!(name: "Weight", data_type: "decimal")
    sign_in @user
  end

  test "create adds a data point and responds with turbo stream" do
    assert_difference -> { @metric.data_points.count }, 1 do
      post metric_data_points_path(@metric),
           params: { data_point: { recorded_at: "2026-01-01T08:00:00Z", value: "72.5" } },
           as: :turbo_stream
    end
    assert_response :success
    assert_match "turbo-stream", response.media_type
  end

  test "create with invalid value re-renders without persisting" do
    assert_no_difference -> { @metric.data_points.count } do
      post metric_data_points_path(@metric),
           params: { data_point: { recorded_at: "2026-01-01T08:00:00Z", value: "abc" } },
           as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "destroy removes the data point" do
    dp = @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "1")
    assert_difference -> { @metric.data_points.count }, -1 do
      delete metric_data_point_path(@metric, dp), as: :turbo_stream
    end
  end

  test "cannot create a data point on another user's metric" do
    other = confirmed_user(email: "intruder1@m.test")
    foreign_metric = other.metrics.create!(name: "Theirs", data_type: "decimal")
    assert_no_difference -> { DataPoint.count } do
      post metric_data_points_path(foreign_metric),
           params: { data_point: { recorded_at: "2026-01-01T08:00:00Z", value: "5" } }
    end
    assert_response :not_found
  end

  test "cannot destroy a data point on another user's metric" do
    other = confirmed_user(email: "intruder2@m.test")
    foreign_metric = other.metrics.create!(name: "Theirs", data_type: "decimal")
    foreign_dp = foreign_metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "1")
    delete metric_data_point_path(foreign_metric, foreign_dp)
    assert_response :not_found
    assert foreign_dp.reload.persisted?
  end
end
