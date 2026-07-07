require "test_helper"

class ChartRasterizerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "r@h.t", password: "password123")
  end

  def series(metric, period: "day", zone: "UTC")
    ChartRasterizer.new(metric, period: period, zone: zone).series
  end

  test "averages multiple readings on the same day into one point" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 20), value: "72")

    result = series(m)
    assert_equal 1, result.size
    assert_in_delta 71.0, result.first.last, 0.0001
  end

  test "fills empty days between readings with the default" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal", default_value: "50")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 4, 8), value: "80")

    travel_to Time.utc(2026, 1, 4, 12) do
      ys = series(m).map(&:last)
      # Jan 1 = 70, Jan 2 = 50 (default), Jan 3 = 50 (default), Jan 4 = 80
      assert_equal [ 70.0, 50.0, 50.0, 80.0 ], ys.map(&:to_f)
    end
  end

  test "does not fill gaps when no default is set" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 4, 8), value: "80")

    travel_to Time.utc(2026, 1, 4, 12) do
      assert_equal [ 70.0, 80.0 ], series(m).map { |_, y| y.to_f }
    end
  end

  test "does not extrapolate before the first reading" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal", default_value: "50")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 2, 8), value: "70")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 3, 8), value: "72")

    travel_to Time.utc(2026, 1, 3, 12) do
      assert_equal Time.utc(2026, 1, 2).to_i, series(m).map(&:first).first.to_i
    end
  end

  test "extends the series to the current day, filling gaps with the default" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal", default_value: "50")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")

    travel_to Time.utc(2026, 1, 4, 12) do
      result = series(m)
      # Jan 1 = 70, then default up to and including "today" (Jan 4).
      assert_equal Time.utc(2026, 1, 4).to_i, result.map(&:first).last.to_i
      assert_equal [ 70.0, 50.0, 50.0, 50.0 ], result.map { |_, y| y.to_f }
    end
  end

  test "does not extend past the last reading when no default is set" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")

    travel_to Time.utc(2026, 1, 4, 12) do
      # With no default the trailing empty days are dropped, so the series still
      # ends at the last reading.
      assert_equal [ Time.utc(2026, 1, 1).to_i ], series(m).map { |s, _| s.to_i }
    end
  end

  test "extends to the current day in the given time zone" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal", default_value: "50")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")

    # 23:30 UTC on Jan 4 is already Jan 5 in Berlin (UTC+1 in winter).
    travel_to Time.utc(2026, 1, 4, 23, 30) do
      last = series(m, zone: "Europe/Berlin").map(&:first).last
      assert_equal "2026-01-05", last.to_date.to_s
    end
  end

  test "empty metric yields an empty series" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal", default_value: "50")
    assert_equal [], series(m)
  end

  test "buckets by week" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 5, 8), value: "70")   # Mon
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 7, 8), value: "72")   # Wed, same ISO week
    result = series(m, period: "week")
    assert_equal 1, result.size
    assert_in_delta 71.0, result.first.last, 0.0001
  end

  test "buckets in the given time zone" do
    m = @user.metrics.create!(name: "Weight", data_type: "decimal")
    # 23:00 UTC on Jan 1 is 00:00 Jan 2 in Berlin (UTC+1 in winter)
    m.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 23), value: "70")
    start = series(m, zone: "Europe/Berlin").first.first
    assert_equal "2026-01-02", start.to_date.to_s
  end
end
