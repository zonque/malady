class DataPoint < ApplicationRecord
  belongs_to :metric

  validates :recorded_at, presence: true
  validate :raw_value_casts

  before_validation :keep_time_of_day_when_ignored

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

  # When the parent metric ignores time, the form submits a date-only value that
  # Active Record parses to midnight. We keep recorded_at a real timestamp by
  # re-attaching a time-of-day: the moment of entry on create, or the previously
  # stored time on edit. This preserves same-day ordering while the UI hides time.
  def keep_time_of_day_when_ignored
    return unless metric&.ignore_time?
    return if recorded_at.blank?

    base = recorded_at_was || Time.current
    self.recorded_at = recorded_at.change(hour: base.hour, min: base.min, sec: base.sec)
  end

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
