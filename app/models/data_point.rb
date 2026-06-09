class DataPoint < ApplicationRecord
  belongs_to :metric

  validates :recorded_at, presence: true
  validate :raw_value_casts

  # Accepts a raw user string, stores it for casting on validation.
  def value=(raw)
    @raw_value = raw
  end

  # Typed read based on the parent metric.
  def value
    return value_decimal if metric&.numeric?
    return value_boolean if metric&.boolean?
    value_text
  end

  private

  def raw_value_casts
    # metric.nil? guard: validations all run even when belongs_to is missing,
    # so without this, a nil metric would NoMethodError on metric.data_type.
    return if @raw_value.nil? || metric.nil?

    casted = ValueCaster.new(metric).cast(@raw_value)
    assign_attributes(casted)
  rescue ValueCaster::Error => e
    errors.add(:value, e.message)
  end
end
