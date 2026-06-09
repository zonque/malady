# Populates a user with a realistic set of health metrics and many data points,
# using Faker for value variety. Idempotent on metrics (find_or_create by name);
# each run appends fresh data points across the given window.
class DemoDataGenerator
  SPECS = [
    { name: "Weight",            data_type: "decimal",     unit: "kg",  gen: -> { Faker::Number.between(from: 60.0, to: 95.0).round(1) } },
    { name: "Resting heart rate", data_type: "integer",    unit: "bpm", gen: -> { Faker::Number.between(from: 48, to: 92) } },
    { name: "Body temperature",  data_type: "decimal",     unit: "°C",  gen: -> { Faker::Number.between(from: 36.0, to: 38.4).round(1) } },
    { name: "Sleep",             data_type: "decimal",     unit: "h",   gen: -> { Faker::Number.between(from: 4.0, to: 9.5).round(1) } },
    { name: "Steps",             data_type: "integer",     unit: "",    gen: -> { Faker::Number.between(from: 800, to: 18000) } },
    { name: "Hydration",         data_type: "percentage",  unit: "%",   gen: -> { Faker::Number.between(from: 25, to: 100) } },
    { name: "Mood",              data_type: "enumeration", enum_options: %w[awful low ok good great], gen: -> { %w[awful low ok good great].sample } },
    { name: "Took medication",   data_type: "boolean",     gen: -> { [true, false].sample } },
  ].freeze

  def initialize(user, days: 60, per_day: 2)
    @user = user
    @days = days
    @per_day = per_day
  end

  def generate!
    SPECS.each do |spec|
      metric = @user.metrics.find_or_create_by!(name: spec[:name]) do |m|
        m.data_type = spec[:data_type]
        m.unit = spec[:unit].to_s
        m.enum_options = spec[:enum_options] || []
      end
      # Ensure enum_options are up to date on an existing metric (idempotent).
      if spec[:enum_options] && metric.enum_options != spec[:enum_options]
        metric.update!(enum_options: spec[:enum_options])
      end
      @days.times do |d|
        @per_day.times do
          recorded_at = (Time.current - d.days).change(hour: rand(6..22), min: rand(0..59)).utc
          metric.data_points.create!(recorded_at: recorded_at, value: spec[:gen].call.to_s)
        end
      end
    end
  end
end
