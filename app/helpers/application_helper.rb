module ApplicationHelper
  def metric_chartable?(metric) = metric.chartable?

  # [[recorded_at, numeric_value], ...] for charting; nil for non-chartable types.
  # Numeric types use value_decimal; boolean maps to 1/0.
  def metric_chart_data(metric)
    case metric.data_type
    when "decimal", "integer", "percentage"
      metric.data_points.order(:recorded_at).filter_map { |dp| [dp.recorded_at, dp.value_decimal] if dp.value_decimal }
    when "boolean"
      metric.data_points.order(:recorded_at).filter_map { |dp| [dp.recorded_at, (dp.value_boolean ? 1 : 0)] unless dp.value_boolean.nil? }
    end
  end

  # Renders the value input appropriate to a metric's data_type.
  # `name` is the form field name, e.g. "data_point[value]" or "values[42]".
  def metric_value_input(metric, name:, value: nil, id: nil)
    base = { class: "form-input", id: id }
    case metric.data_type
    when "enumeration"
      select_tag name, options_for_select(Array(metric.enum_options), value),
                 include_blank: true, class: "form-select", id: id
    when "boolean"
      select_tag name, options_for_select([[t("boolean.yes"), "true"], [t("boolean.no"), "false"]], value),
                 include_blank: true, class: "form-select", id: id
    when "integer"
      number_field_tag name, value, base.merge(step: 1)
    when "decimal", "percentage"
      number_field_tag name, value, base.merge(step: "any")
    else # text
      text_field_tag name, value, base
    end
  end
end
