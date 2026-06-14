require "test_helper"

class Daylio::CsvExportTest < ActiveSupport::TestCase
  # The real Daylio CSV export: tab-separated, 8 columns, activities joined by
  # " | ", note_title often empty, note holds the journal text (unicode-safe).
  TAB_EXPORT = <<~CSV
    full_date\tdate\tweekday\ttime\tmood\tactivities\tnote_title\tnote
    2026-05-20\tMay 20\tWednesday\t22:13\tgood\t\t\t
    2026-05-14\tMay 14\tThursday\t22:00\tgood\trelaxed | medium sleep | Workout | family | friends\t\t
    2026-05-13\tMay 13\tWednesday\t22:20\tgood\texcited | good sleep | family\t\tLorem ipsum dolor sit amet, café au lait 🙂
  CSV

  # A comma-separated variant with a quoted note containing a comma.
  COMMA_EXPORT = <<~CSV
    full_date,date,weekday,time,mood,activities,note_title,note
    2026-05-20,May 20,Wednesday,22:13,rad,exercise | work,Morning,"Felt great, rested"
    2026-05-19,May 19,Tuesday,22:00,meh,,,
  CSV

  test "parses the tab-separated 8-column export" do
    export = Daylio::CsvExport.parse(TAB_EXPORT)
    assert_equal 3, export.entries.size

    first = export.entries.first
    assert_equal Date.new(2026, 5, 20), first.date
    assert_equal 22, first.hour
    assert_equal 13, first.minute
    assert_equal "good", first.mood
    assert_empty first.activities
    assert_not first.note?

    assert_equal [ "relaxed", "medium sleep", "Workout", "family", "friends" ], export.entries[1].activities

    third = export.entries[2]
    assert_equal [ "excited", "good sleep", "family" ], third.activities
    assert third.note?
    assert_equal "Lorem ipsum dolor sit amet, café au lait 🙂", third.note
  end

  test "parses a comma-separated export with quoted notes" do
    export = Daylio::CsvExport.parse(COMMA_EXPORT)
    first, second = export.entries

    assert_equal [ "exercise", "work" ], first.activities
    assert_equal "Morning", first.note_title
    assert_equal "Felt great, rested", first.note
    assert first.note?
    assert_not second.note?
    assert_equal "meh", second.mood
  end

  test "collects distinct activities and moods across entries" do
    export = Daylio::CsvExport.parse(TAB_EXPORT)
    assert_equal [ "relaxed", "medium sleep", "Workout", "family", "friends", "excited", "good sleep" ],
                 export.activities
    assert_equal [ "good" ], export.moods
  end

  test "reads from a file" do
    file = Tempfile.new([ "export", ".csv" ])
    file.write(TAB_EXPORT)
    file.close
    export = Daylio::CsvExport.read(file.path)
    assert_equal 3, export.entries.size
  ensure
    file&.unlink
  end

  test "rejects a CSV that is not a Daylio export" do
    assert_raises(Daylio::CsvExport::Error) do
      Daylio::CsvExport.parse("a,b,c\n1,2,3\n")
    end
  end

  test "parses despite a leading UTF-8 BOM (Daylio prepends one)" do
    export = Daylio::CsvExport.parse("﻿#{TAB_EXPORT}")
    assert_equal 3, export.entries.size
    assert_equal "good", export.entries.first.mood
  end

  test "tolerates CRLF line endings" do
    export = Daylio::CsvExport.parse(COMMA_EXPORT.gsub("\n", "\r\n"))
    assert_equal 2, export.entries.size
    assert_equal [ "exercise", "work" ], export.entries.first.activities
  end
end
