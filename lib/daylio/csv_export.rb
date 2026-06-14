require "csv"

module Daylio
  # Parses a Daylio CSV export (Settings → Export → CSV). The export is a table
  # with columns: full_date, date, weekday, time, mood, activities, note_title,
  # note. The delimiter is auto-detected (Daylio uses tab; comma/semicolon
  # variants are also handled).
  #
  #   export = Daylio::CsvExport.read("daylio_export.csv")
  #   export.entries.each { |e| puts e.date, e.mood, e.activities.inspect }
  class CsvExport
    Error = Class.new(StandardError)

    REQUIRED_HEADERS = %w[full_date time mood].freeze

    attr_reader :entries

    def self.read(path)
      parse(File.read(path))
    rescue SystemCallError => e
      raise Error, "could not read #{path}: #{e.message}"
    end

    def self.parse(string)
      new(string)
    end

    def initialize(string)
      # Daylio prepends a UTF-8 BOM; left in place it corrupts the first header.
      string = string.to_s.dup.force_encoding("UTF-8").delete_prefix("﻿")
      table = CSV.parse(string, headers: true, col_sep: delimiter_for(string), skip_blanks: true)
      missing = REQUIRED_HEADERS - Array(table.headers).map(&:to_s)
      raise Error, "not a Daylio CSV export (missing columns: #{missing.join(', ')})" if missing.any?

      @entries = table.map { |row| CsvEntry.new(row) }
    rescue CSV::MalformedCSVError => e
      raise Error, "malformed CSV: #{e.message}"
    end

    # Distinct activity names across all entries (first-appearance order).
    def activities
      @entries.flat_map(&:activities).uniq
    end

    # Distinct mood names across all entries.
    def moods
      @entries.filter_map(&:mood).uniq
    end

    private

    def delimiter_for(string)
      header = string.each_line.first.to_s
      return "\t" if header.include?("\t")
      return ";"  if header.include?(";") && !header.include?(",")

      ","
    end
  end
end
