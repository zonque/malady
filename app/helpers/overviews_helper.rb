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
    else I18n.l(start, format: :ov_day_header)
    end
  end

  def overview_point_time(time, period, zone, ignore_time: false)
    local = time.in_time_zone(zone)
    return I18n.l(local, format: :ov_point_date) if ignore_time

    format = case period
    when "week" then :ov_week_point
    when "month" then :ov_month_point
    else :ov_day_point
    end
    I18n.l(local, format: format)
  end

  def overview_stat(value)
    return "—" if value.nil?
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
  end

  private

  # The numeric y-value for a data point: 1/0 for boolean, the option index for an
  # enumeration, otherwise the stored decimal.
  def chart_y(metric, dp)
    return dp.value_boolean.nil? ? nil : (dp.value_boolean ? 1 : 0) if metric.boolean?
    return metric.enum_index(dp.value_text) if metric.enumeration?
    dp.value_decimal
  end
end
