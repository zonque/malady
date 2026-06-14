require "date"

module Daylio
  # One row of a Daylio CSV export: a date + time, a mood name, a list of
  # activities, and an optional journal note (title + body).
  class CsvEntry
    # Activities are joined by " | " within the single CSV field.
    ACTIVITY_SEPARATOR = "|"

    attr_reader :note_title, :note

    def initialize(row)
      @full_date  = row["full_date"].to_s.strip
      @time_str   = row["time"].to_s.strip
      @mood       = row["mood"].to_s.strip
      @activities = row["activities"].to_s
      @note_title = row["note_title"].to_s
      @note       = row["note"].to_s
    end

    # The entry's calendar date (Date), or nil if unparseable.
    def date
      return unless @full_date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      Date.strptime(@full_date, "%Y-%m-%d")
    rescue ArgumentError
      nil
    end

    def hour   = time_parts&.first
    def minute = time_parts&.last

    def mood
      @mood.empty? ? nil : @mood
    end

    # Activity names recorded on this entry, in order.
    def activities
      @activities.split(ACTIVITY_SEPARATOR).map(&:strip).reject(&:empty?)
    end

    # True when the entry carries any journal text (note body or title).
    def note?
      !@note.strip.empty? || !@note_title.strip.empty?
    end

    private

    def time_parts
      return @time_parts if defined?(@time_parts)

      @time_parts =
        if (m = @time_str.match(/\A(\d{1,2}):(\d{2})\z/))
          [ m[1].to_i, m[2].to_i ]
        end
    end
  end
end
