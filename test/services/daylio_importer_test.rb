require "test_helper"

class DaylioImporterTest < ActiveSupport::TestCase
  # full_date,date,weekday,time,mood,activities,note_title,note
  SAMPLE = <<~CSV
    full_date,date,weekday,time,mood,activities,note_title,note
    2026-05-20,May 20,Wednesday,22:13,good,exercise | good sleep | drink water,Title,"Lorem ipsum, dolor sit"
    2026-05-19,May 19,Tuesday,22:00,rad,exercise | medium sleep,,
    2026-05-18,May 18,Monday,21:00,meh,bad sleep,,
  CSV

  setup do
    @user = User.create!(email: "daylio@h.t", password: "password123", time_zone: "UTC")
  end

  def export(csv = SAMPLE)
    Daylio::CsvExport.parse(csv)
  end

  def import!(dry_run: false, csv: SAMPLE)
    DaylioImporter.new(user: @user, export: export(csv), dry_run: dry_run, logger: Logger.new(IO::NULL)).import!
  end

  test "creates a yes/no metric per plain activity with a true point per occurrence" do
    import!
    exercise = @user.metrics.find_by(name: "exercise")
    water = @user.metrics.find_by(name: "drink water")

    assert_equal "boolean", exercise.data_type
    assert_equal 2, exercise.data_points.count
    assert exercise.data_points.all? { |dp| dp.value_boolean == true }
    assert_equal "boolean", water.data_type
    assert_equal 1, water.data_points.count
  end

  test "fuzzy-groups good/medium/bad activities into one Choice metric by suffix" do
    import!
    sleep = @user.metrics.find_by(name: "sleep")

    assert_equal "enumeration", sleep.data_type
    assert_equal %w[good medium bad], sleep.enum_options
    # ordered by recorded_at: 18th bad, 19th medium, 20th good
    assert_equal %w[bad medium good], sleep.data_points.order(:recorded_at).map(&:value_text)
    # the graded variants are NOT created as their own metrics
    assert_nil @user.metrics.find_by(name: "good sleep")
    assert_nil @user.metrics.find_by(name: "medium sleep")
  end

  test "records the correct UTC timestamp from date + time" do
    import!
    exercise = @user.metrics.find_by(name: "exercise")
    assert_includes exercise.data_points.map { |dp| dp.recorded_at.utc }, Time.utc(2026, 5, 20, 22, 13)
  end

  test "creates a Mood choice metric ordered best-to-worst with a value per entry" do
    import!
    mood = @user.metrics.find_by(name: "Mood")
    assert_equal "enumeration", mood.data_type
    assert_equal %w[rad good meh], mood.enum_options
    assert_equal %w[meh rad good], mood.data_points.order(:recorded_at).map(&:value_text)
  end

  test "keeps journal notes in a text_block with the title as an h1" do
    import!
    journal = @user.metrics.find_by(name: "Journal")
    assert_equal "text_block", journal.data_type
    assert_equal 1, journal.data_points.count
    text = journal.data_points.first.value_text
    assert_includes text, "# Title"
    assert_includes text, "Lorem ipsum, dolor sit"
  end

  test "note_to_markdown translates Daylio note html into markdown" do
    assert_equal "Line one\nLine two\nLine three",
                 DaylioImporter.note_to_markdown("Line one<br>Line two<br/>Line three")
    assert_equal "Para one\n\nPara two",
                 DaylioImporter.note_to_markdown("<p>Para one</p><p>Para two</p>")
    assert_equal "**bold** and *italic* and ~~gone~~",
                 DaylioImporter.note_to_markdown("<b>bold</b> and <i>italic</i> and <s>gone</s>")
    assert_equal "- a\n- b",
                 DaylioImporter.note_to_markdown("<ul><li>a</li><li>b</li></ul>")
    assert_equal "Tom & Jerry",
                 DaylioImporter.note_to_markdown("Tom &amp; Jerry")
  end

  test "journal notes with html line breaks are stored as markdown" do
    csv = <<~CSV
      full_date,date,weekday,time,mood,activities,note_title,note
      2026-05-20,May 20,Wednesday,22:13,good,,,"First line<br>Second line"
    CSV
    DaylioImporter.new(user: @user, export: export(csv), logger: Logger.new(IO::NULL)).import!
    text = @user.metrics.find_by(name: "Journal").data_points.first.value_text
    assert_equal "First line\nSecond line", text
  end

  test "converts a pre-existing same-named metric to the type the import needs" do
    # A "Journal" metric that already exists as plain text (e.g. created manually
    # or by an older import) must end up as text_block, not be reused as-is —
    # otherwise it never shows up under dashboard Memories.
    existing = @user.metrics.create!(name: "Journal", data_type: "text")
    existing.data_points.create!(recorded_at: Time.utc(2025, 1, 1, 9), value: "an older note")

    import!(csv: <<~CSV)
      full_date,date,weekday,time,mood,activities,note_title,note
      2026-05-20,May 20,Wednesday,22:13,good,,,"A new note"
    CSV

    journal = @user.metrics.find_by(name: "Journal")
    assert_equal "text_block", journal.data_type
    # The pre-existing value is preserved through the conversion.
    assert_includes journal.data_points.map(&:value_text), "an older note"
    assert_includes journal.data_points.map(&:value_text), "A new note"
  end

  test "dry run reports what would happen but persists nothing" do
    summary = import!(dry_run: true)
    assert_equal 0, @user.metrics.count
    assert_equal 0, DataPoint.count
    assert summary.dry_run
    assert_operator summary.metrics_created, :>, 0
    assert_operator summary.points_created, :>, 0
  end

  test "re-running is idempotent: reuses metrics and skips duplicate points" do
    import!
    assert_difference -> { DataPoint.count }, 0 do
      assert_difference -> { Metric.count }, 0 do
        summary = import!
        assert_equal 0, summary.points_created
        assert_operator summary.points_skipped, :>, 0
        assert_operator summary.metrics_reused, :>, 0
      end
    end
  end
end
