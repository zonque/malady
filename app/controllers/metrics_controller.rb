class MetricsController < ApplicationController
  before_action :set_metric, only: [ :show, :edit, :update, :destroy ]

  DATA_POINTS_PER_PAGE = 10

  # The metrics index is the period overview: every metric's readings bucketed by
  # day/week/month, with per-bucket charts and stats.
  def index
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

  def show
    @page = [ params[:page].to_i, 1 ].max
    scope = @metric.data_points.order(recorded_at: :desc, id: :desc)
    @total_pages = [ (scope.count / DATA_POINTS_PER_PAGE.to_f).ceil, 1 ].max
    @data_points = scope.offset((@page - 1) * DATA_POINTS_PER_PAGE).limit(DATA_POINTS_PER_PAGE)
    @data_point = @metric.data_points.new(recorded_at: Time.current)
  end

  def new
    @metric = current_user.metrics.new
  end

  def edit; end

  def create
    @metric = current_user.metrics.new(metric_params)
    if @metric.save
      redirect_to @metric, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @metric.update(metric_params)
      redirect_to @metric, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @metric.destroy
    redirect_to metrics_path, notice: t(".deleted")
  end

  private

  def set_metric
    @metric = current_user.metrics.find(params[:id])
  end

  def metric_params
    permitted = params.require(:metric).permit(:name, :description, :note, :data_type, :unit, :color, :icon, :position, :active, :ignore_time, enum_options: [])
    if (preset = Metric::PRESETS[permitted[:data_type]])
      permitted.merge!(preset)
    end
    permitted
  end
end
