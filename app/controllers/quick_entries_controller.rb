class QuickEntriesController < ApplicationController
  def new
    @metrics = current_user.metrics.where(active: true).ordered
    @recorded_at = Time.current
    @values = {}
    @drafts = {}
  end

  def create
    @metrics = current_user.metrics.where(active: true).ordered
    @recorded_at = params[:recorded_at]
    @values = {}
    @drafts = {}

    @metrics.each do |metric|
      raw = params.dig(:values, metric.id.to_s)
      @values[metric.id] = raw
      @drafts[metric.id] = metric.data_points.new(recorded_at: @recorded_at, value: raw) if raw.present?
    end

    if @drafts.empty?
      flash.now[:alert] = t(".no_values")
      return render :new, status: :unprocessable_entity
    end

    if @drafts.values.all?(&:valid?)
      DataPoint.transaction { @drafts.each_value(&:save!) }
      count = @drafts.size
      redirect_to root_path, notice: t(".logged", count: count)
    else
      flash.now[:alert] = t(".invalid")
      render :new, status: :unprocessable_entity
    end
  end
end
