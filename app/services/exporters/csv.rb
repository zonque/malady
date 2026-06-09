require "csv"

module Exporters
  class Csv
    HEADERS = %w[metric_slug metric_name recorded_at value unit note].freeze

    def initialize(user)
      @user = user
    end

    def to_csv
      CSV.generate do |csv|
        csv << HEADERS
        @user.metrics.ordered.each do |metric|
          metric.data_points.order(:recorded_at).each do |dp|
            csv << [ metric.slug, metric.name, dp.recorded_at.utc.iso8601, dp.value_text, metric.unit, dp.note ]
          end
        end
      end
    end
  end
end
