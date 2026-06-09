module Exporters
  class Json
    def initialize(user)
      @user = user
    end

    def as_json(*)
      {
        exported_at: Time.current.utc.iso8601,
        metrics: @user.metrics.ordered.map { |m| metric_hash(m) }
      }
    end

    def to_json(*)
      as_json.to_json
    end

    private

    def metric_hash(metric)
      {
        name: metric.name,
        slug: metric.slug,
        data_type: metric.data_type,
        unit: metric.unit,
        enum_options: metric.enum_options,
        data_points: metric.data_points.order(:recorded_at).map { |dp|
          {
            recorded_at: dp.recorded_at.utc.iso8601,
            value_text: dp.value_text,
            value_decimal: dp.value_decimal,
            value_boolean: dp.value_boolean,
            note: dp.note
          }
        }
      }
    end
  end
end
