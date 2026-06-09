module Api
  module V1
    class MetricsController < BaseController
      def index
        render json: current_user.metrics.ordered.map { |m| metric_json(m) }
      end

      def show
        metric = current_user.metrics.find_by!(slug: params[:slug])
        render json: metric_json(metric)
      end

      def series
        metric = current_user.metrics.find_by!(slug: params[:slug])
        scope = metric.data_points.order(:recorded_at)
        scope = scope.where(recorded_at: params[:from]..) if params[:from].present?
        scope = scope.where(recorded_at: ..params[:to]) if params[:to].present?
        render json: scope.map { |dp| { time: dp.recorded_at.utc.iso8601, value: series_value(metric, dp) } }
      end

      private

      def metric_json(metric)
        { slug: metric.slug, name: metric.name, data_type: metric.data_type, unit: metric.unit }
      end

      # Grafana expects numeric series. Coerce BigDecimal → Float (Rails would
      # otherwise JSON-encode a BigDecimal as a STRING like "0.72e2"). Booleans
      # become 1/0; non-numeric types fall back to their text value.
      def series_value(metric, dp)
        if metric.numeric?
          dp.value_decimal&.to_f
        elsif metric.boolean?
          dp.value_boolean.nil? ? nil : (dp.value_boolean ? 1 : 0)
        else
          dp.value_text
        end
      end
    end
  end
end
