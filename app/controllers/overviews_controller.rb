class OverviewsController < ApplicationController
  def show
    @period = OverviewReport::PERIODS.include?(params[:period]) ? params[:period] : "day"
    metrics = current_user.metrics.ordered
    @report = OverviewReport.new(metrics,
                                 period: @period,
                                 time_zone: current_user.time_zone,
                                 page: params[:page])
    @buckets = @report.buckets
    @chartable_metrics = metrics.select(&:chartable?)
    @selected_slugs = params[:metrics].nil? ? @chartable_metrics.map(&:slug) : Array(params[:metrics]).reject(&:blank?)
    @selected_ids = @chartable_metrics.select { |m| @selected_slugs.include?(m.slug) }.map(&:id)
  end
end
