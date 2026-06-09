class DashboardController < ApplicationController
  def show
    @metrics = current_user.metrics.ordered
    @counts = DataPoint.where(metric: @metrics).group(:metric_id).count
    @last_recorded = DataPoint.where(metric: @metrics).group(:metric_id).maximum(:recorded_at)
  end
end
