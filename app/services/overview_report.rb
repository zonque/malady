# Period-centric overview: buckets every metric's data points into day/week/month
# windows (in the given timezone), most-recent-first, paginated. Each bucket lists
# the metrics that have readings in it, with count + min/max/avg and the points.
# Pure Ruby (portable across SQLite/Postgres); fine at personal-tracker scale.
class OverviewReport
  PERIODS = %w[day week month].freeze
  PER_PAGE = 10

  attr_reader :period, :page, :total_pages

  def initialize(metrics, period:, time_zone: "UTC", page: 1)
    @metrics = metrics.to_a
    @period = PERIODS.include?(period.to_s) ? period.to_s : "day"
    @zone = Time.find_zone(time_zone) || Time.find_zone("UTC")
    @page = [page.to_i, 1].max
    @total_pages = 1
  end

  def buckets
    by_metric = {}
    starts = []
    @metrics.each do |metric|
      grouped = metric.data_points.order(:recorded_at).group_by { |dp| bucket_start(dp.recorded_at) }
      by_metric[metric] = grouped
      starts.concat(grouped.keys)
    end

    sorted = starts.uniq.sort.reverse
    @total_pages = [(sorted.size / PER_PAGE.to_f).ceil, 1].max
    window = sorted.slice((@page - 1) * PER_PAGE, PER_PAGE) || []

    window.map do |start|
      entries = @metrics.filter_map do |metric|
        dps = by_metric[metric][start]
        next unless dps&.any?

        decimals = dps.filter_map(&:value_decimal)
        {
          metric: metric,
          points: dps.sort_by(&:recorded_at),
          count: dps.size,
          min: decimals.min,
          max: decimals.max,
          avg: (decimals.sum / decimals.size if decimals.any?)
        }
      end
      { start: start, entries: entries }
    end
  end

  private

  def bucket_start(time)
    local = time.in_time_zone(@zone)
    case @period
    when "week" then local.beginning_of_week
    when "month" then local.beginning_of_month
    else local.beginning_of_day
    end
  end
end
