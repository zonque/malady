if Rails.env.development?
  user = User.find_or_create_by!(email: "demo@malady.test") do |u|
    u.password = "password123"
    u.confirmed_at = Time.current # confirmable: make the demo user able to sign in
  end
  weight = user.metrics.find_or_create_by!(name: "Weight") { |m| m.data_type = "decimal"; m.unit = "kg" }
  weight.data_points.find_or_create_by!(recorded_at: Time.utc(2026, 1, 1, 8)) { |d| d.value = "72.5" }
end

AdminProvisioner.new.call # no-op unless MALADY_ADMIN_EMAIL/PASSWORD are set
