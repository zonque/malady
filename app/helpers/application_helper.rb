module ApplicationHelper
  def metric_chartable?(metric) = metric.chartable?

  # [[recorded_at, numeric_value], ...] for charting; nil for non-chartable types.
  # Numeric types use value_decimal; boolean maps to 1/0.
  def metric_chart_data(metric)
    case metric.data_type
    when "decimal", "integer", "percentage"
      metric.data_points.order(:recorded_at).filter_map { |dp| [ dp.recorded_at, dp.value_decimal ] if dp.value_decimal }
    when "boolean"
      metric.data_points.order(:recorded_at).filter_map { |dp| [ dp.recorded_at, (dp.value_boolean ? 1 : 0) ] unless dp.value_boolean.nil? }
    end
  end

  # Renders the value input appropriate to a metric's data_type.
  # `name` is the form field name, e.g. "data_point[value]" or "values[42]".
  def metric_value_input(metric, name:, value: nil, id: nil)
    # Default to the name-derived id so callers that omit `id` still get a stable,
    # addressable element. Passing `id: nil` straight through to the *_tag helpers
    # would suppress the auto-generated id entirely.
    id ||= sanitize_to_id(name)
    base = { class: "form-input", id: id }
    case metric.data_type
    when "enumeration"
      select_tag name, options_for_select(Array(metric.enum_options), value),
                 include_blank: true, class: "form-select", id: id
    when "boolean"
      select_tag name, options_for_select([ [ t("boolean.yes"), "true" ], [ t("boolean.no"), "false" ] ], value),
                 include_blank: true, class: "form-select", id: id
    when "integer"
      number_field_tag name, value, base.merge(step: 1)
    when "decimal", "percentage"
      number_field_tag name, value, base.merge(step: "any")
    when "text_block"
      # Resizable (native handle) textarea for longer entries such as a journal.
      text_area_tag name, value, base.merge(rows: 8, style: "resize: vertical")
    else # text
      text_field_tag name, value, base
    end
  end

  # The display markup for a logged value. For text_block, the stored Markdown is
  # rendered to sanitized HTML in a prose block; every other type shows its plain
  # value_text inline (value_text is the canonical display string — see _data_point).
  def metric_value_display(metric, data_point)
    if metric.text_block?
      content_tag :div, render_markdown(data_point.value_text), class: "markdown-body"
    else
      content_tag :span, data_point.value_text, class: "font-mono text-gray-900 dark:text-gray-100"
    end
  end

  # Renders a metric's Bootstrap icon as an <i class="bi bi-NAME">, or nil when no
  # icon is set. The icon name is format-validated (kebab-case) on the model, so it
  # is safe to interpolate into the class attribute.
  def metric_icon_tag(metric, **options)
    return if metric.icon.blank?

    classes = [ "bi", "bi-#{metric.icon}", options.delete(:class) ].compact.join(" ")
    content_tag :i, "", { class: classes, "aria-hidden": "true" }.merge(options)
  end

  # Human label for a memory's anniversary interval, e.g. "3 months ago" or
  # "2 years ago". Whole years (multiples of 12) read as years.
  def memory_label(months)
    if (months % 12).zero?
      t("memories.years_ago", count: months / 12)
    else
      t("memories.months_ago", count: months)
    end
  end

  # Renders a Markdown string to sanitized HTML. Raw/inline HTML is stripped by
  # Redcarpet (filter_html) and again by Rails' sanitize as a defense-in-depth layer.
  def render_markdown(text)
    sanitize(MARKDOWN.render(text.to_s))
  end

  MARKDOWN = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true),
    autolink: true,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    no_intra_emphasis: true
  )
end
