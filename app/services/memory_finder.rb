# Surfaces past text_block ("journal") entries whose anniversary lands on or near
# today — a "memory" / "on this day" feature for the dashboard.
#
# Anniversary intervals are 1, 3, 6, 9 months, then yearly (12, 24, 36, ...).
# An entry is a memory when today is within WINDOW_DAYS of one of those
# anniversaries; month-length differences are handled by Date#>> (Jan 31 + 1
# month clamps to Feb 28/29).
class MemoryFinder
  BASE_INTERVALS = [ 1, 3, 6, 9 ].freeze
  WINDOW_DAYS = 1

  Memory = Struct.new(:data_point, :metric, :interval_months, keyword_init: true)

  def initialize(user, today: Date.current)
    @user = user
    @today = today
  end

  def memories
    metrics = @user.metrics.where(data_type: "text_block").index_by(&:id)
    return [] if metrics.empty?

    DataPoint.where(metric_id: metrics.keys).filter_map { |dp|
      months = matching_interval(dp.recorded_at.to_date)
      next unless months

      Memory.new(data_point: dp, metric: metrics[dp.metric_id], interval_months: months)
    }.sort_by(&:interval_months)
  end

  private

  # The smallest anniversary interval (in months) landing within WINDOW_DAYS of
  # today, or nil when the entry has no anniversary near today.
  def matching_interval(date)
    candidate_intervals(date).each do |n|
      anniversary = date >> n
      break if anniversary > @today + WINDOW_DAYS # intervals ascending: nothing later can match
      return n if (anniversary - @today).abs <= WINDOW_DAYS
    end
    nil
  end

  def candidate_intervals(date)
    months_old = ((@today.year - date.year) * 12) + (@today.month - date.month)
    yearly = (12..(months_old + 12)).step(12).to_a
    BASE_INTERVALS + yearly
  end
end
