require "test_helper"

class MetricTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "a@b.c", password: "password123")
  end

  test "valid metric" do
    m = @user.metrics.build(name: "Weight", data_type: "decimal")
    assert m.valid?
  end

  test "slug is generated from name and unique per user" do
    @user.metrics.create!(name: "Weight", data_type: "decimal")
    dup = @user.metrics.build(name: "Weight", data_type: "decimal")
    assert_not dup.valid?
    assert_includes dup.errors[:slug], "has already been taken"
  end

  test "rejects unknown data_type" do
    # enum is declared with `validate: true`, so an unknown value does NOT raise
    # on assignment (Rails 7.1+ behavior) — it makes the record invalid instead.
    m = @user.metrics.build(name: "X", data_type: "bogus")
    assert_not m.valid?
    assert m.errors[:data_type].any?
  end

  test "enumeration requires options" do
    m = @user.metrics.build(name: "Flow", data_type: "enumeration", enum_options: [])
    assert_not m.valid?
    assert_includes m.errors[:enum_options], "can't be blank"
  end

  test "numeric? and boolean? helpers" do
    assert @user.metrics.build(data_type: "percentage").numeric?
    assert @user.metrics.build(data_type: "boolean").boolean?
  end

  test "chartable? for numeric and boolean only" do
    %w[decimal integer percentage boolean].each { |t| assert @user.metrics.build(data_type: t).chartable? }
    %w[enumeration text text_block].each { |t| assert_not @user.metrics.build(data_type: t).chartable? }
  end

  test "text_block is a valid, non-numeric, non-chartable type" do
    m = @user.metrics.create!(name: "Journal", data_type: "text_block")
    assert m.text_block?
    assert_not m.numeric?
    assert_not m.chartable?
  end
end
