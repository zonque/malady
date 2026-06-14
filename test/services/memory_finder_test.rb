require "test_helper"

class MemoryFinderTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "mem@h.t", password: "password123")
    @journal = @user.metrics.create!(name: "Journal", data_type: "text_block")
    @today = Date.new(2026, 6, 14)
  end

  def note(date, value: "entry", metric: @journal)
    metric.data_points.create!(recorded_at: date.to_time(:utc).change(hour: 9), value: value)
  end

  def intervals_for(*data_points)
    found = MemoryFinder.new(@user, today: @today).memories
    by_dp = found.index_by(&:data_point)
    data_points.map { |dp| by_dp[dp]&.interval_months }
  end

  test "matches an entry from exactly one month ago" do
    dp = note(@today << 1) # 2026-05-14
    assert_equal [ 1 ], intervals_for(dp)
  end

  test "matches the 3/6/9/12 month anniversaries" do
    three  = note(@today << 3)
    six    = note(@today << 6)
    nine   = note(@today << 9)
    twelve = note(@today << 12)
    assert_equal [ 3, 6, 9, 12 ], intervals_for(three, six, nine, twelve)
  end

  test "matches yearly anniversaries after the first year" do
    two_yr  = note(@today << 24)
    three_yr = note(@today << 36)
    assert_equal [ 24, 36 ], intervals_for(two_yr, three_yr)
  end

  test "matches within a +/- 2 day window but not beyond" do
    plus_two  = note((@today << 1) + 2)
    minus_two = note((@today << 1) - 2)
    plus_three = note((@today << 1) + 3)
    assert_equal [ 1, 1, nil ], intervals_for(plus_two, minus_two, plus_three)
  end

  test "does not match a non-anniversary entry" do
    dp = note(@today << 2) # 2 months ago is not an interval
    assert_equal [ nil ], intervals_for(dp)
  end

  test "handles month-end clamping (Jan 31 + 1 month)" do
    today = Date.new(2026, 2, 28)
    dp = @journal.data_points.create!(recorded_at: Time.utc(2026, 1, 31, 9), value: "x")
    found = MemoryFinder.new(@user, today: today).memories
    assert_equal [ 1 ], found.map(&:interval_months)
  end

  test "ignores non-text_block notes" do
    text   = @user.metrics.create!(name: "Note", data_type: "text")
    number = @user.metrics.create!(name: "Weight", data_type: "decimal")
    note(@today << 1, metric: text)
    note(@today << 1, value: "70", metric: number)
    assert_empty MemoryFinder.new(@user, today: @today).memories
  end

  test "ignores other users' notes" do
    other = User.create!(email: "other@h.t", password: "password123")
    other_journal = other.metrics.create!(name: "Theirs", data_type: "text_block")
    other_journal.data_points.create!(recorded_at: (@today << 1).to_time(:utc), value: "secret")
    assert_empty MemoryFinder.new(@user, today: @today).memories
  end

  test "sorts memories by interval ascending" do
    note(@today << 12)
    note(@today << 1)
    note(@today << 6)
    assert_equal [ 1, 6, 12 ], MemoryFinder.new(@user, today: @today).memories.map(&:interval_months)
  end
end
