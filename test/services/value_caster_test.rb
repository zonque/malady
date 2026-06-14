require "test_helper"

class ValueCasterTest < ActiveSupport::TestCase
  def cast(type, raw, enum_options: [])
    metric = Metric.new(data_type: type, enum_options: enum_options)
    ValueCaster.new(metric).cast(raw)
  end

  test "decimal parses numbers and rejects junk" do
    assert_equal({ value_text: "3.5", value_decimal: 3.5, value_boolean: nil }, cast("decimal", "3.5"))
    assert_raises(ValueCaster::Error) { cast("decimal", "abc") }
  end

  test "integer truncates representation but rejects non-integers" do
    assert_equal({ value_text: "42", value_decimal: 42, value_boolean: nil }, cast("integer", "42"))
    assert_raises(ValueCaster::Error) { cast("integer", "4.2") }
  end

  test "percentage requires 0..100" do
    assert_equal 80.0, cast("percentage", "80")[:value_decimal]
    assert_raises(ValueCaster::Error) { cast("percentage", "150") }
  end

  test "boolean coerces truthy/falsey strings" do
    assert_equal({ value_text: "true", value_decimal: nil, value_boolean: true }, cast("boolean", "yes"))
    assert_equal false, cast("boolean", "0")[:value_boolean]
    assert_raises(ValueCaster::Error) { cast("boolean", "maybe") }
  end

  test "enumeration must be a member" do
    opts = [ "light", "heavy" ]
    assert_equal "light", cast("enumeration", "light", enum_options: opts)[:value_text]
    assert_raises(ValueCaster::Error) { cast("enumeration", "nope", enum_options: opts) }
  end

  test "text accepts any non-blank string" do
    assert_equal "hello", cast("text", "hello")[:value_text]
    assert_raises(ValueCaster::Error) { cast("text", "  ") }
  end

  test "text_block accepts multiline strings and rejects blank" do
    multiline = "# Title\n\nFirst line\nSecond line"
    assert_equal multiline, cast("text_block", multiline)[:value_text]
    assert_raises(ValueCaster::Error) { cast("text_block", "  ") }
  end

  test "rejects non-finite numbers" do
    assert_raises(ValueCaster::Error) { cast("decimal", "Infinity") }
    assert_raises(ValueCaster::Error) { cast("decimal", "-Infinity") }
    assert_raises(ValueCaster::Error) { cast("decimal", "NaN") }
  end

  test "numeric value_text is normalized (whole floats lose the decimal)" do
    assert_equal "80", cast("percentage", "80")[:value_text]
    assert_equal "80.5", cast("percentage", "80.5")[:value_text]
    assert_equal "3", cast("decimal", "3.0")[:value_text]
  end

  test "boolean is case-insensitive with canonical value_text" do
    assert_equal true,  cast("boolean", "YES")[:value_boolean]
    assert_equal false, cast("boolean", "Off")[:value_boolean]
    assert_equal "true", cast("boolean", "On")[:value_text]
  end

  test "text preserves surrounding whitespace (only all-blank is rejected)" do
    assert_equal "  hi  ", cast("text", "  hi  ")[:value_text]
  end

  test "enumeration trims surrounding whitespace for a lenient match" do
    assert_equal "light", cast("enumeration", " light ", enum_options: [ "light", "heavy" ])[:value_text]
  end
end
