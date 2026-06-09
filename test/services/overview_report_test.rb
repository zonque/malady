require "test_helper"

class OverviewReportTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "a@b.c", password: "password123")
    @weight = @user.metrics.create!(name: "Weight", data_type: "decimal")
    @mood = @user.metrics.create!(name: "Mood", data_type: "enumeration", enum_options: [ "low", "high" ])
  end

  def report(period: "day", page: 1, time_zone: "UTC")
    OverviewReport.new(@user.metrics.ordered, period: period, time_zone: time_zone, page: page)
  end

  test "groups all metrics under shared day buckets, newest first" do
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 20), value: "72")
    @mood.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 9), value: "low")
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 2, 8), value: "74")

    buckets = report.buckets
    assert_equal 2, buckets.size
    assert_operator buckets.first[:start], :>, buckets.last[:start] # newest first
    jan1 = buckets.last
    # both metrics appear under Jan 1
    names = jan1[:entries].map { |e| e[:metric].name }
    assert_includes names, "Weight"
    assert_includes names, "Mood"
    weight_entry = jan1[:entries].find { |e| e[:metric] == @weight }
    assert_equal 2, weight_entry[:count]
    assert_equal 70, weight_entry[:min]
    assert_equal 72, weight_entry[:max]
    assert_equal 71, weight_entry[:avg]
    assert_equal [ 70, 72 ], weight_entry[:points].map { |dp| dp.value_decimal.to_i } # chronological
  end

  test "non-numeric metric: count present, min/max/avg nil" do
    @mood.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 9), value: "low")
    entry = report.buckets.first[:entries].find { |e| e[:metric] == @mood }
    assert_equal 1, entry[:count]
    assert_nil entry[:min]
    assert_nil entry[:avg]
  end

  test "paginates 10 buckets per page" do
    12.times { |i| @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1 + i, 8), value: "70") }
    r1 = report(page: 1)
    assert_equal 10, r1.buckets.size
    assert_equal 2, r1.total_pages
    r2 = report(page: 2)
    assert_equal 2, r2.buckets.size
  end

  test "week and month grouping" do
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 2, 8), value: "72") # same ISO week + month
    assert_equal 1, report(period: "week").buckets.size
    assert_equal 1, report(period: "month").buckets.size
  end

  test "buckets in the given timezone" do
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 2, 3), value: "70") # 22:00 Jan 1 in NY
    assert_equal 1, report(period: "day", time_zone: "America/New_York").buckets.first[:start].day
  end

  test "invalid period falls back to day; invalid tz to UTC" do
    @weight.data_points.create!(recorded_at: Time.utc(2026, 1, 2, 3), value: "70")
    assert_equal 2, OverviewReport.new(@user.metrics, period: "bogus", time_zone: "Bad/Zone", page: 1).buckets.first[:start].day
  end
end
