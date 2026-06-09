class ValueCaster
  Error = Class.new(StandardError)

  EMPTY = { value_text: nil, value_decimal: nil, value_boolean: nil }.freeze

  TRUE_TOKENS  = %w[true t yes y 1 on].freeze
  FALSE_TOKENS = %w[false f no n 0 off].freeze

  def initialize(metric)
    @metric = metric
  end

  # Returns { value_text:, value_decimal:, value_boolean: } or raises Error.
  def cast(raw)
    case @metric.data_type
    when "decimal"     then numeric(raw)
    when "integer"     then integer(raw)
    when "percentage"  then percentage(raw)
    when "boolean"     then boolean(raw)
    when "enumeration" then enumeration(raw)
    when "text"        then text(raw)
    else raise Error, "unknown data_type #{@metric.data_type.inspect}"
    end
  end

  private

  def numeric(raw)
    f = Float(raw.to_s.strip)
    # ValueCaster::Error is not an ArgumentError, so this propagates past the rescue.
    raise Error, "#{raw.inspect} is not a finite number" unless f.finite?
    EMPTY.merge(value_text: normalize_number(f), value_decimal: f)
  rescue ArgumentError, TypeError
    raise Error, "#{raw.inspect} is not a number"
  end

  def integer(raw)
    i = Integer(raw.to_s.strip, 10)
    EMPTY.merge(value_text: i.to_s, value_decimal: i)
  rescue ArgumentError, TypeError
    raise Error, "#{raw.inspect} is not an integer"
  end

  def percentage(raw)
    result = numeric(raw)
    unless result[:value_decimal].between?(0, 100)
      raise Error, "percentage must be between 0 and 100"
    end
    result
  end

  def boolean(raw)
    v = raw.to_s.strip.downcase
    return EMPTY.merge(value_text: "true",  value_boolean: true)  if TRUE_TOKENS.include?(v)
    return EMPTY.merge(value_text: "false", value_boolean: false) if FALSE_TOKENS.include?(v)
    raise Error, "#{raw.inspect} is not yes/no"
  end

  def enumeration(raw)
    v = raw.to_s.strip
    unless @metric.enum_options.include?(v)
      raise Error, "#{v.inspect} is not one of #{@metric.enum_options.inspect}"
    end
    EMPTY.merge(value_text: v)
  end

  def text(raw)
    v = raw.to_s
    raise Error, "text can't be blank" if v.strip.empty?
    EMPTY.merge(value_text: v)
  end

  def normalize_number(f)
    f == f.to_i ? f.to_i.to_s : f.to_s
  end
end
