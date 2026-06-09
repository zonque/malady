require "test_helper"

class DataPointTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "a@b.c", password: "password123")
    @metric = @user.metrics.create!(name: "Weight", data_type: "decimal")
  end

  test "assigning value casts and projects columns" do
    dp = @metric.data_points.new(recorded_at: Time.utc(2026, 1, 1), value: "72.5")
    assert dp.save
    assert_equal "72.5", dp.value_text
    assert_equal 72.5, dp.value_decimal
    assert_nil dp.value_boolean
  end

  test "invalid value adds an error instead of raising" do
    dp = @metric.data_points.new(recorded_at: Time.utc(2026, 1, 1), value: "abc")
    assert_not dp.save
    assert_includes dp.errors[:value].join, "not a number"
  end

  test "value reader returns the typed value" do
    bmetric = @user.metrics.create!(name: "Fasting", data_type: "boolean")
    dp = bmetric.data_points.create!(recorded_at: Time.utc(2026, 1, 1), value: "yes")
    assert_equal true, dp.value
  end

  test "recorded_at is required" do
    dp = @metric.data_points.new(value: "1")
    assert_not dp.save
    assert_includes dp.errors[:recorded_at], "can't be blank"
  end
end
