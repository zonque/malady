# Rasterizes a metric's readings into one numeric point per period bucket
# (day/week/month) in the given time zone. Same-bucket readings are averaged.
# The series runs from the first reading through the current bucket ("now" in the
# given zone), so the chart always reaches today rather than stopping at the last
# reading. Empty buckets — whether between readings or trailing after the last one
# — are filled with the metric's default_chart_value; when no default is set, gaps
# are left unfilled. Nothing is invented before the first reading.
# Pure Ruby (portable across SQLite/Postgres); fine at personal-tracker scale.
class ChartRasterizer
  PERIODS = %w[day week month].freeze

  def initialize(metric, period: "day", zone: "UTC")
    @metric = metric
    @period = PERIODS.include?(period.to_s) ? period.to_s : "day"
    @zone = Time.find_zone(zone) || Time.find_zone("UTC")
  end

  # [[bucket_start (Time), y (Numeric)], ...] ascending by bucket start.
  def series
    averages = bucket_averages
    return [] if averages.empty?

    default = @metric.default_chart_value
    last = [ averages.keys.max, bucket_start(Time.current) ].max
    each_bucket(averages.keys.min, last).filter_map do |start|
      y = averages.fetch(start, default)
      [ start, y ] unless y.nil?
    end
  end

  private

  # { bucket_start => average_y } for buckets that actually have readings.
  def bucket_averages
    grouped = Hash.new { |h, k| h[k] = [] }
    @metric.data_points.order(:recorded_at).each do |dp|
      y = @metric.chart_value(dp)
      grouped[bucket_start(dp.recorded_at)] << y unless y.nil?
    end
    grouped.transform_values { |ys| ys.sum.to_f / ys.size }
  end

  # Every bucket start from first to last inclusive, stepping by the period.
  def each_bucket(first, last)
    return enum_for(:each_bucket, first, last) unless block_given?

    current = first
    while current <= last
      yield current
      current = step(current)
    end
  end

  def step(start)
    case @period
    when "week"  then start + 1.week
    when "month" then start + 1.month
    else start + 1.day
    end
  end

  def bucket_start(time)
    local = time.in_time_zone(@zone)
    case @period
    when "week"  then local.beginning_of_week
    when "month" then local.beginning_of_month
    else local.beginning_of_day
    end
  end
end
