module OverviewsHelper
  # Build chart series for a section's entries, limited to chartable + selected
  # metrics. Each series: { label:, points: [{ x: epoch_ms, y: actual_value }] }.
  # Boolean values map to 1/0; enumerations map to the chosen option's index. The
  # view JSON-encodes this for the Stimulus chart.
  def overview_chart_series(entries, selected_ids)
    entries.filter_map do |entry|
      metric = entry[:metric]
      next unless metric.chartable? && selected_ids.include?(metric.id)

      points = entry[:points].filter_map do |dp|
        y = chart_y(metric, dp)
        { x: (dp.recorded_at.to_f * 1000).round, y: y.to_f } unless y.nil?
      end
      { label: metric.name, points: points } if points.any?
    end
  end

  def overview_period_label(start, period)
    case period
    when "week" then t("metrics.index.period_label.week", date: I18n.l(start, format: :ov_week_date), cw: start.to_date.cweek)
    when "month" then I18n.l(start, format: :ov_month_header)
    else relative_day(start) || I18n.l(start, format: :ov_day_header)
    end
  end

  def overview_point_time(time, period, zone, ignore_time: false)
    local = time.in_time_zone(zone)
    rel = relative_day(local)
    return rel || I18n.l(local, format: :ov_point_date) if ignore_time

    case period
    # The day section already names the day in its header, so points show time only.
    when "day"   then I18n.l(local, format: :ov_day_point)
    when "week"  then relative_point(rel, local) || I18n.l(local, format: :ov_week_point)
    else              relative_point(rel, local) || I18n.l(local, format: :ov_month_point)
    end
  end

  def overview_stat(value)
    return "—" if value.nil?
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
  end

  private

  # "Today"/"Yesterday" when the (zoned) date is within a day of now, else nil so
  # callers fall back to an absolute format. `local` is a zoned time/date.
  def relative_day(local)
    case (local.to_date - Time.current.in_time_zone(local.time_zone).to_date).to_i
    when 0  then t("dates.today")
    when -1 then t("dates.yesterday")
    end
  end

  # A point label that swaps the date portion for "Today"/"Yesterday" but keeps the
  # time of day; nil when there's no relative word to substitute.
  def relative_point(rel, local)
    "#{rel} #{I18n.l(local, format: :ov_day_point)}" if rel
  end

  # The numeric y-value for a data point — delegates to the metric so the
  # projection lives in exactly one place (see Metric#chart_value).
  def chart_y(metric, dp)
    metric.chart_value(dp)
  end
end
