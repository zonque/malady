class MetricTypesController < ApplicationController
  before_action :set_metric

  def edit
    @target_type = params[:target_type].presence || @metric.data_type
    @report = MetricTypeChanger.new(@metric).dry_run(@target_type) if valid_target?
  end

  def update
    target = params.require(:target_type)
    unless Metric::DATA_TYPES.include?(target)
      redirect_to edit_metric_metric_type_path(@metric), alert: t(".unknown_type") and return
    end
    MetricTypeChanger.new(@metric).apply!(target)
    redirect_to @metric, notice: t(".changed", type: target)
  end

  private

  def set_metric
    @metric = current_user.metrics.find(params[:metric_id])
  end

  def valid_target?
    Metric::DATA_TYPES.include?(@target_type)
  end
end
