require "cgi"
require "set"

# Imports a parsed Daylio CSV export into a user's metrics:
#   - plain activities      -> a yes/no (boolean) metric each, with a `true` point
#                              per occurrence;
#   - graded activities     -> activities named "<grade> <suffix>" where grade is
#                              good/medium/bad are fuzzy-grouped by suffix into a
#                              single Choice metric "<suffix>" with good/medium/bad
#                              options (e.g. "good sleep"/"medium sleep" -> "sleep");
#   - mood                  -> a single "Mood" Choice metric (rad..awful order);
#   - notes                 -> a single "Journal" text_block metric, with the note
#                              title as a leading "# " heading.
#
# Metrics are matched/reused by name and points are de-duplicated by
# (metric, recorded_at), so re-running an import is idempotent. A dry run does
# the full pass inside a transaction and rolls it back.
class DaylioImporter
  MOOD_METRIC = "Mood"
  JOURNAL_METRIC = "Journal"
  # Mood names in Daylio's default best-to-worst order; unknown/custom moods are
  # appended in order of appearance.
  DEFAULT_MOOD_ORDER = %w[rad good meh bad awful].freeze
  # Grade prefixes that fold "<grade> <suffix>" activities into one Choice metric.
  GRADES = %w[good medium bad].freeze
  NBSP = " " # non-breaking space (&nbsp;)

  Summary = Struct.new(
    :metrics_created, :metrics_reused, :points_created, :points_skipped, :dry_run,
    keyword_init: true
  )

  # Daylio stores notes as HTML. Translate the tags it uses into the Markdown our
  # text_block metric renders: line/paragraph breaks, emphasis, and bullet lists.
  def self.note_to_markdown(html)
    text = html.to_s.gsub(/\r\n?/, "\n")
    text = text.gsub(%r{<\s*br\s*/?\s*>}i, "\n")                        # line break
    text = text.gsub(%r{</\s*p\s*>}i, "\n\n").gsub(%r{<\s*p[^>]*>}i, "") # paragraphs
    text = text.gsub(%r{</\s*div\s*>}i, "\n").gsub(%r{<\s*div[^>]*>}i, "")
    text = text.gsub(%r{<\s*li[^>]*>}i, "- ").gsub(%r{</\s*li\s*>}i, "\n") # list items
    text = text.gsub(%r{</?\s*[ou]l[^>]*>}i, "")
    text = text.gsub(%r{</?\s*(?:b|strong)\s*>}i, "**")                 # bold
    text = text.gsub(%r{</?\s*(?:i|em)\s*>}i, "*")                      # italic
    text = text.gsub(%r{</?\s*(?:s|strike|del)\s*>}i, "~~")             # strikethrough
    text = text.gsub(/<[^>]+>/, "")                                     # drop anything else
    text = CGI.unescapeHTML(text).gsub(NBSP, " ")                       # entities, nbsp -> space
    text.gsub(/[ \t]+\n/, "\n").gsub(/\n{3,}/, "\n\n").strip            # tidy whitespace
  end

  def initialize(user:, export:, dry_run: false, logger: Logger.new($stdout))
    @user = user
    @export = export
    @dry_run = dry_run
    @log = logger
    @zone = ActiveSupport::TimeZone[user.time_zone] || ActiveSupport::TimeZone["UTC"]
    @summary = Summary.new(
      metrics_created: 0, metrics_reused: 0, points_created: 0, points_skipped: 0,
      dry_run: dry_run
    )
    @existing_times = {}
  end

  def import!
    log "Daylio CSV: #{@export.entries.size} entries, " \
        "#{@export.activities.size} activities, #{@export.moods.size} moods"

    ActiveRecord::Base.transaction do
      import_activities
      import_moods
      import_journal

      if @dry_run
        log "rolling back — dry run, nothing saved"
        raise ActiveRecord::Rollback
      end
    end

    log "done — metrics: #{@summary.metrics_created} created, #{@summary.metrics_reused} reused; " \
        "points: #{@summary.points_created} created, #{@summary.points_skipped} skipped"
    @summary
  end

  private

  def import_activities
    plain = Hash.new { |h, k| h[k] = [] }          # activity name -> [time, ...]
    graded = Hash.new { |h, k| h[k] = { name: nil, points: [] } } # suffix key -> {name:, points: [[time, grade]]}

    @export.entries.each do |entry|
      next unless (time = recorded_at(entry))

      entry.activities.each do |activity|
        grade, suffix = grade_split(activity)
        if grade
          group = graded[suffix.downcase]
          group[:name] ||= suffix
          group[:points] << [ time, grade ]
        else
          plain[activity] << time
        end
      end
    end

    plain.each do |name, times|
      metric = find_or_create_metric(name, data_type: "boolean")
      times.each { |time| add_point(metric, time, "yes") }
    end

    graded.each_value do |group|
      metric = find_or_create_metric(group[:name], data_type: "enumeration", enum_options: GRADES)
      merge_enum_options(metric, GRADES)
      group[:points].each { |time, grade| add_point(metric, time, grade) }
    end
  end

  # Splits "good sleep" into ["good", "sleep"]; returns [nil, nil] when the
  # activity isn't a good/medium/bad-prefixed grade with a suffix.
  def grade_split(activity)
    first, rest = activity.split(" ", 2)
    return [ nil, nil ] if rest.nil? || rest.strip.empty?
    return [ nil, nil ] unless GRADES.include?(first.downcase)

    [ first.downcase, rest.strip ]
  end

  def import_moods
    entries = @export.entries.select { |e| e.mood && recorded_at(e) }
    return if entries.empty?

    names = ordered_mood_names(entries.map(&:mood).uniq)
    metric = find_or_create_metric(MOOD_METRIC, data_type: "enumeration", enum_options: names)
    merge_enum_options(metric, names)

    entries.each { |e| add_point(metric, recorded_at(e), e.mood) }
  end

  def import_journal
    entries = @export.entries.select { |e| e.note? && recorded_at(e) }
    return if entries.empty?

    metric = find_or_create_metric(JOURNAL_METRIC, data_type: "text_block")
    entries.each { |e| add_point(metric, recorded_at(e), journal_text(e)) }
  end

  def ordered_mood_names(used)
    defaults = DEFAULT_MOOD_ORDER.select { |m| used.include?(m) }
    defaults + (used - DEFAULT_MOOD_ORDER)
  end

  def journal_text(entry)
    body = self.class.note_to_markdown(entry.note)
    title = entry.note_title.to_s.strip
    return body if title.empty?

    [ "# #{title}", body ].reject(&:empty?).join("\n\n")
  end

  def recorded_at(entry)
    date = entry.date or return nil

    @zone.local(date.year, date.month, date.day, entry.hour || 0, entry.minute || 0)
  end

  def find_or_create_metric(name, data_type:, enum_options: [])
    existing = @user.metrics.find_by(name: name)

    if existing.nil?
      metric = @user.metrics.create!(name: name, data_type: data_type, enum_options: enum_options)
      @summary.metrics_created += 1
      log "create #{data_type} metric #{name.inspect}"
      return metric
    end

    @summary.metrics_reused += 1

    # A same-named metric of a different type would otherwise be reused as-is —
    # e.g. a "Journal" that pre-exists as `text` would never become `text_block`,
    # and so never appear under dashboard Memories. Convert it to the type the
    # import needs. This is lossless: value_text is the source of truth and is
    # preserved; numeric/boolean projections are recomputed for the new type.
    if existing.data_type != data_type
      from = existing.data_type
      existing.update!(enum_options: enum_options) if enum_options.any?
      MetricTypeChanger.new(existing).apply!(data_type)
      log "convert metric #{name.inspect} (#{from} → #{data_type})"
      return existing.reload
    end

    log "reuse metric #{name.inspect} (#{data_type})"
    existing
  end

  def merge_enum_options(metric, names)
    merged = metric.enum_options | names
    return if merged == metric.enum_options

    metric.update!(enum_options: merged)
  end

  def add_point(metric, time, value)
    if seen_times(metric).include?(time.to_i)
      @summary.points_skipped += 1
      return
    end

    metric.data_points.create!(recorded_at: time, value: value)
    seen_times(metric) << time.to_i
    @summary.points_created += 1
  rescue ActiveRecord::RecordInvalid => e
    @summary.points_skipped += 1
    log "skip point for #{metric.name.inspect} at #{time.iso8601}: #{e.record.errors.full_messages.to_sentence}"
  end

  # Per-metric set of already-present recorded_at values (epoch seconds), seeded
  # from the database so re-imports don't duplicate points.
  def seen_times(metric)
    @existing_times[metric.id] ||= Set.new(metric.data_points.pluck(:recorded_at).map(&:to_i))
  end

  def log(message)
    @log.info("#{'[dry-run] ' if @dry_run}#{message}")
  end
end
