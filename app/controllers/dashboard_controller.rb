class DashboardController < ApplicationController
  def show
    @metrics = current_user.metrics.ordered
    @counts = DataPoint.where(metric: @metrics).group(:metric_id).count
    @last_recorded = DataPoint.where(metric: @metrics).group(:metric_id).maximum(:recorded_at)
    # Date.current is the user's local date (use_user_time_zone around_action).
    @memories = MemoryFinder.new(current_user, today: Date.current).memories
  end
end
