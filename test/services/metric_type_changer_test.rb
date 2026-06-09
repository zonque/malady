require "test_helper"

class MetricTypeChangerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "a@b.c", password: "password123")
    @metric = @user.metrics.create!(name: "Reading", data_type: "text")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "10")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 2), value: "20")
    @metric.data_points.create!(recorded_at: Time.utc(2026, 1, 3), value: "oops")
  end

  test "dry_run reports convertible vs failing counts" do
    report = MetricTypeChanger.new(@metric).dry_run("decimal")
    assert_equal 3, report.total
    assert_equal 2, report.convertible
    assert_equal 1, report.failing
    assert_equal 1, report.samples.size
    assert_equal "oops", report.samples.first
  end

  test "dry_run with a fully lossless target reports zero failures" do
    report = MetricTypeChanger.new(@metric).dry_run("text")
    assert_equal 0, report.failing
  end

  test "apply! sets new type and reprojects typed columns" do
    MetricTypeChanger.new(@metric).apply!("decimal")
    @metric.reload
    assert_equal "decimal", @metric.data_type

    ok = @metric.data_points.find_by(recorded_at: Time.utc(2026, 1, 1))
    assert_equal 10.0, ok.value_decimal
    assert_equal "10", ok.value_text

    failed = @metric.data_points.find_by(recorded_at: Time.utc(2026, 1, 3))
    assert_nil failed.value_decimal
    assert_equal "oops", failed.value_text # original preserved
  end

  test "apply! clears stale projections from the previous type" do
    MetricTypeChanger.new(@metric).apply!("decimal")
    MetricTypeChanger.new(@metric.reload).apply!("text")
    dp = @metric.data_points.find_by(recorded_at: Time.utc(2026, 1, 1))
    assert_nil dp.value_decimal
    assert_nil dp.value_boolean
    assert_equal "10", dp.value_text
  end
end
