class MetricTypeChanger
  Report = Struct.new(:total, :convertible, :failing, :samples, keyword_init: true)

  MAX_SAMPLES = 5

  def initialize(metric)
    @metric = metric
  end

  def apply!(target_type)
    probe = Metric.new(data_type: target_type, enum_options: @metric.enum_options)
    caster = ValueCaster.new(probe)

    @metric.transaction do
      @metric.update!(data_type: target_type)
      @metric.data_points.find_each do |dp|
        projected =
          begin
            caster.cast(dp.value_text).slice(:value_decimal, :value_boolean)
          rescue ValueCaster::Error
            { value_decimal: nil, value_boolean: nil }
          end
        dp.update_columns(projected) # value_text untouched; skip callbacks/validation
      end
    end
  end

  def dry_run(target_type)
    probe = Metric.new(data_type: target_type, enum_options: @metric.enum_options)
    caster = ValueCaster.new(probe)

    total = 0
    failing_values = []

    @metric.data_points.find_each do |dp|
      total += 1
      begin
        caster.cast(dp.value_text)
      rescue ValueCaster::Error
        failing_values << dp.value_text
      end
    end

    Report.new(
      total: total,
      convertible: total - failing_values.size,
      failing: failing_values.size,
      samples: failing_values.first(MAX_SAMPLES)
    )
  end
end
