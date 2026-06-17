require "test_helper"

class OverviewsHelperTest < ActionView::TestCase
  test "overview_chart_series builds series for chartable + selected metrics only" do
    user = User.create!(email: "ch@h.t", password: "password123")
    weight = user.metrics.create!(name: "Weight", data_type: "decimal")
    note = user.metrics.create!(name: "Note", data_type: "text")
    weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 9), value: "80")
    note.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "hello")

    entries = OverviewReport.new(user.metrics.ordered, period: "day").buckets.first[:entries]

    # both selected, but only chartable (weight) produces a series
    series = overview_chart_series(entries, [ weight.id, note.id ])
    assert_equal [ "Weight" ], series.map { |s| s[:label] }
    assert_equal 2, series.first[:points].size
    assert_equal 70.0, series.first[:points].first[:y]   # actual value, not normalized
    assert_kind_of Integer, series.first[:points].first[:x]  # epoch ms

    # weight not selected → no series
    assert_empty overview_chart_series(entries, [ note.id ])
  end

  test "overview_chart_series charts an enumeration by option index" do
    user = User.create!(email: "ch3@h.t", password: "password123")
    mood = user.metrics.create!(name: "Mood", data_type: "enumeration", enum_options: %w[low ok high])
    mood.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "ok")
    mood.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 9), value: "high")
    entries = OverviewReport.new(user.metrics.ordered, period: "day").buckets.first[:entries]
    assert_equal [ 1.0, 2.0 ], overview_chart_series(entries, [ mood.id ]).first[:points].map { |p| p[:y] }
  end

  test "overview_chart_series maps boolean to 1/0" do
    user = User.create!(email: "ch2@h.t", password: "password123")
    b = user.metrics.create!(name: "Took meds", data_type: "boolean")
    b.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "yes")
    b.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 9), value: "no")
    entries = OverviewReport.new(user.metrics.ordered, period: "day").buckets.first[:entries]
    assert_equal [ 1.0, 0.0 ], overview_chart_series(entries, [ b.id ]).first[:points].map { |p| p[:y] }
  end

  test "period label per grouping" do
    start = Time.utc(2026, 2, 2).in_time_zone("UTC") # Monday of ISO week 6
    assert_match "February 2026", overview_period_label(start, "month")
    assert_match "Week of", overview_period_label(start, "week")
    assert_match "CW 6", overview_period_label(start, "week") # calendar week number
    assert_match "2026", overview_period_label(start, "day")
  end

  test "point time granularity per grouping" do
    t = Time.utc(2026, 2, 2, 8, 5) # Monday
    assert_equal "08:05", overview_point_time(t, "day", "UTC") # day header already names the weekday
    assert_match %r{\AMon 08:05\z}, overview_point_time(t, "week", "UTC")
    assert_match "Mon", overview_point_time(t, "month", "UTC") # weekday alongside the date
    assert_match "Feb", overview_point_time(t, "month", "UTC")
  end

  test "ignore_time points show the weekday with the date" do
    t = Time.utc(2026, 2, 2, 8, 5) # Monday
    label = overview_point_time(t, "day", "UTC", ignore_time: true)
    assert_match "Mon", label
    assert_match "Feb", label
  end

  test "today and yesterday replace the date in point labels" do
    now = Time.current.in_time_zone("UTC").change(hour: 8, min: 5)

    assert_match "Today", overview_point_time(now, "month", "UTC")
    assert_match "Yesterday", overview_point_time(now - 1.day, "month", "UTC")
    assert_no_match(/Today|Yesterday/, overview_point_time(now - 5.days, "month", "UTC"))

    # week view substitutes the weekday; ignore_time substitutes the whole date
    assert_match "Today", overview_point_time(now, "week", "UTC")
    assert_match "Yesterday", overview_point_time(now - 1.day, "day", "UTC", ignore_time: true)

    # the time is still shown alongside the relative word
    assert_match "08:05", overview_point_time(now, "month", "UTC")
  end

  test "day section header reads Today and Yesterday" do
    today = Time.current.in_time_zone("UTC").beginning_of_day
    assert_equal "Today", overview_period_label(today, "day")
    assert_equal "Yesterday", overview_period_label(today - 1.day, "day")
    assert_no_match(/Today|Yesterday/, overview_period_label(today - 5.days, "day"))
  end

  test "stat formatting" do
    assert_equal "—", overview_stat(nil)
    assert_equal "71", overview_stat(71)
    assert_equal "71.5", overview_stat(71.5)
  end
end
