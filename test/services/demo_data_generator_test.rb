require "test_helper"

class DemoDataGeneratorTest < ActiveSupport::TestCase
  setup { @user = User.create!(email: "demo@x.c", password: "password123") }

  test "creates the full set of varied metrics" do
    assert_difference -> { @user.metrics.count }, DemoDataGenerator::SPECS.size do
      DemoDataGenerator.new(@user, days: 2, per_day: 1).generate!
    end
    # variety: at least one enumeration and one boolean and one numeric
    assert @user.metrics.exists?(data_type: "enumeration")
    assert @user.metrics.exists?(data_type: "boolean")
    assert @user.metrics.exists?(data_type: "decimal")
  end

  test "creates data points with valid (persisted) values for each metric" do
    DemoDataGenerator.new(@user, days: 3, per_day: 2).generate!
    @user.metrics.each do |m|
      assert m.data_points.any?, "#{m.name} should have data points"
      m.data_points.each { |dp| assert dp.value_text.present? }
    end
  end

  test "re-running adds more data points but does not duplicate metrics" do
    DemoDataGenerator.new(@user, days: 1, per_day: 1).generate!
    metric_count = @user.metrics.count
    point_count = DataPoint.where(metric: @user.metrics).count
    DemoDataGenerator.new(@user, days: 1, per_day: 1).generate!
    assert_equal metric_count, @user.metrics.count
    assert_operator DataPoint.where(metric: @user.metrics).count, :>, point_count
  end
end
