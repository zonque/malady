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

  test "ignore_time metric create from a date string stores a full timestamp" do
    metric = @user.metrics.create!(name: "Episode", data_type: "boolean", ignore_time: true)
    travel_to Time.utc(2026, 3, 4, 14, 30) do
      post metric_data_points_path(metric),
           params: { data_point: { recorded_at: "2026-03-04", value: "true" } },
           as: :turbo_stream
      dp = metric.data_points.last
      assert_in_delta Time.current.to_i, dp.recorded_at.to_i, 60
    end
  end

  test "ignore_time metric renders a date-only input and hides time in the timeline" do
    metric = @user.metrics.create!(name: "Episode", data_type: "boolean", ignore_time: true)
    metric.data_points.create!(recorded_at: Time.utc(2026, 3, 4, 14, 30), value: "true")
    get metric_path(metric)
    assert_response :success
    assert_select "input[type=date][name=?]", "data_point[recorded_at]"
    assert_select "#data_points time[data-date-only]"
  end

  test "normal metric renders a datetime input without the date-only flag" do
    @metric.data_points.create!(recorded_at: Time.utc(2026, 3, 4, 14, 30), value: "1")
    get metric_path(@metric)
    assert_response :success
    assert_select "input[type=?][name=?]", "datetime-local", "data_point[recorded_at]"
    assert_select "#data_points time[data-date-only]", count: 0
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

  test "each timeline row links to editing the reading" do
    dp = @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "72")
    get metric_path(@metric)
    assert_response :success
    assert_select "a[href=?]", edit_metric_data_point_path(@metric, dp)
  end

  test "the delete control requires confirmation" do
    dp = @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "72")
    get metric_path(@metric)
    assert_response :success
    assert_select "form[action=?][data-turbo-confirm]", metric_data_point_path(@metric, dp)
  end

  test "edit renders the shared form prefilled with the reading's value" do
    dp = @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "72.5")
    get edit_metric_data_point_path(@metric, dp)
    assert_response :success
    assert_select "form[action=?]", metric_data_point_path(@metric, dp)
    assert_select "input[name=?][value=?]", "data_point[value]", "72.5"
  end

  test "edit of a text_block reading uses a textarea prefilled with the markdown" do
    journal = @user.metrics.create!(name: "Journal", data_type: "text_block")
    dp = journal.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "# Title\n\nbody")
    get edit_metric_data_point_path(journal, dp)
    assert_response :success
    assert_select "textarea[name=?]", "data_point[value]" do |els|
      assert_match "# Title", els.first.text
    end
  end

  test "update changes the reading and redirects to the metric" do
    dp = @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "72")
    patch metric_data_point_path(@metric, dp), params: { data_point: { value: "73.4", note: "after lunch" } }
    assert_redirected_to metric_path(@metric)
    dp.reload
    assert_equal 73.4, dp.value_decimal
    assert_equal "after lunch", dp.note
  end

  test "update with an invalid value re-renders the edit form" do
    dp = @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "72")
    patch metric_data_point_path(@metric, dp), params: { data_point: { value: "abc" } }
    assert_response :unprocessable_entity
    assert_equal 72, dp.reload.value_decimal
  end

  # Edit/update are scoped through the same `current_user.metrics.find` as create
  # and destroy (covered above), so cross-user access yields 404 the same way.
end
