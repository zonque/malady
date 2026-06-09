class DataPointsController < ApplicationController
  before_action :set_metric
  before_action :set_data_point, only: [ :edit, :update, :destroy ]

  def create
    @data_point = @metric.data_points.new(data_point_params)
    if @data_point.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @metric }
      end
    else
      render turbo_stream: turbo_stream.replace(
        "data_point_form",
        partial: "data_points/form",
        locals: { metric: @metric, data_point: @data_point }
      ), status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @data_point.update(data_point_params)
      redirect_to @metric, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @data_point.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @metric }
    end
  end

  private

  def set_metric
    @metric = current_user.metrics.find(params[:metric_id])
  end

  def set_data_point
    @data_point = @metric.data_points.find(params[:id])
  end

  def data_point_params
    params.require(:data_point).permit(:recorded_at, :value, :note)
  end
end
