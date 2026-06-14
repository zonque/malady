# Daylio export parser — a small, dependency-light Ruby library for reading
# Daylio CSV exports. It has no Rails dependencies and can be lifted out of this
# tree and used on its own; it only needs the standard library (csv, date).
#
#   require "daylio"
#   export = Daylio.read_csv("daylio_export.csv")
#   export.entries.each { |e| puts e.date, e.mood, e.activities.inspect, e.note }
module Daylio
  LIBRARY_VERSION = "0.2.0"

  # Convenience entry point: read and parse a Daylio CSV export at `path`.
  def self.read_csv(path) = CsvExport.read(path)
end

# Under Rails these are autoloaded by Zeitwerk (lib is on the autoload path).
# Standalone, eager-require the pieces so a bare `require "daylio"` is enough.
unless defined?(Rails)
  require_relative "daylio/csv_entry"
  require_relative "daylio/csv_export"
end
