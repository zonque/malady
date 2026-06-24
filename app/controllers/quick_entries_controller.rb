class QuickEntriesController < ApplicationController
  def new
    @metrics = current_user.metrics.where(active: true).ordered
    @recorded_at = Time.current
    @values = {}
    @drafts = {}
    load_logged_today_ids
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
      load_logged_today_ids
      flash.now[:alert] = t(".no_values")
      return render :new, status: :unprocessable_entity
    end

    if @drafts.values.all?(&:valid?)
      DataPoint.transaction { @drafts.each_value(&:save!) }
      count = @drafts.size
      redirect_to root_path, notice: t(".logged", count: count)
    else
      load_logged_today_ids
      flash.now[:alert] = t(".invalid")
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Ids of the user's metrics that already have a reading in today's local-zone
  # day. Time.zone is the browser's synced zone, so this is "since local midnight
  # today." One query, materialized into a Set for O(1) lookup in the view.
  def load_logged_today_ids
    @logged_today_ids = current_user.metrics
      .joins(:data_points)
      .where(data_points: { recorded_at: Time.zone.now.all_day })
      .distinct.pluck("metrics.id").to_set
  end
end
