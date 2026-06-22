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

  test "numeric and boolean metrics are chartable; free text is not" do
    %w[decimal integer percentage boolean].each { |t| assert @user.metrics.build(data_type: t).chartable? }
    %w[text text_block].each { |t| assert_not @user.metrics.build(data_type: t).chartable? }
  end

  test "an enumeration with options is chartable (plotted by option index)" do
    assert @user.metrics.build(data_type: "enumeration", enum_options: %w[0 1 2 3 4 5]).chartable?
    assert @user.metrics.build(data_type: "enumeration", enum_options: %w[low high]).chartable?
    assert_not @user.metrics.build(data_type: "enumeration", enum_options: []).chartable?
  end

  test "text_block is a valid, non-numeric, non-chartable type" do
    m = @user.metrics.create!(name: "Journal", data_type: "text_block")
    assert m.text_block?
    assert_not m.numeric?
    assert_not m.chartable?
  end

  test "icon is optional and accepts kebab-case bootstrap icon names" do
    assert @user.metrics.build(name: "A", data_type: "text", icon: nil).valid?
    assert @user.metrics.build(name: "B", data_type: "text", icon: "").valid?
    assert @user.metrics.build(name: "C", data_type: "text", icon: "heart-fill").valid?
    assert @user.metrics.build(name: "D", data_type: "text", icon: "0-circle").valid?
  end

  test "icon rejects values that could break out of the class attribute" do
    %w[heart\ fill "onerror Heart-Fill -leading trailing- heart_fill].each do |bad|
      m = @user.metrics.build(name: "X", data_type: "text", icon: bad)
      assert_not m.valid?, "expected #{bad.inspect} to be invalid"
      assert m.errors[:icon].any?
    end
  end

  test "default_value accepts a castable value for a chartable metric" do
    m = @user.metrics.build(name: "Weight", data_type: "decimal", default_value: "70")
    assert m.valid?, m.errors.full_messages.to_sentence
  end

  test "default_value rejects an uncastable value for a chartable metric" do
    m = @user.metrics.build(name: "Weight", data_type: "decimal", default_value: "abc")
    assert_not m.valid?
    assert m.errors[:default_value].any?
  end

  test "default_value blank is always allowed" do
    m = @user.metrics.build(name: "Weight", data_type: "decimal", default_value: "")
    assert m.valid?, m.errors.full_messages.to_sentence
  end

  test "default_value is not validated for non-chartable types" do
    m = @user.metrics.build(name: "Journal", data_type: "text", default_value: "anything")
    assert m.valid?, m.errors.full_messages.to_sentence
  end

  test "default_value must be a member for enumeration" do
    ok = @user.metrics.build(name: "Mood", data_type: "enumeration", enum_options: %w[low high], default_value: "low")
    bad = @user.metrics.build(name: "Mood2", data_type: "enumeration", enum_options: %w[low high], default_value: "nope")
    assert ok.valid?, ok.errors.full_messages.to_sentence
    assert_not bad.valid?
  end

  test "default_chart_value projects per type, nil when unset" do
    assert_nil @user.metrics.build(data_type: "decimal").default_chart_value
    assert_equal 70, @user.metrics.build(data_type: "decimal", default_value: "70").default_chart_value
    assert_equal 1, @user.metrics.build(data_type: "boolean", default_value: "yes").default_chart_value
    assert_equal 0, @user.metrics.build(data_type: "boolean", default_value: "no").default_chart_value
    mood = @user.metrics.build(data_type: "enumeration", enum_options: %w[low ok high], default_value: "high")
    assert_equal 2, mood.default_chart_value
  end

  test "chart_value projects a data point per type" do
    weight = @user.metrics.create!(name: "Weight", data_type: "decimal")
    dp = weight.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "70")
    assert_equal 70, weight.chart_value(dp)

    meds = @user.metrics.create!(name: "Meds", data_type: "boolean")
    dp_yes = meds.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "yes")
    assert_equal 1, meds.chart_value(dp_yes)

    mood = @user.metrics.create!(name: "Mood", data_type: "enumeration", enum_options: %w[low ok high])
    dp_high = mood.data_points.create!(recorded_at: Time.utc(2026, 1, 1, 8), value: "high")
    assert_equal 2, mood.chart_value(dp_high)
  end
end
