# Idempotently ensures an admin account exists, driven by ENV. Safe to run on
# every deploy/seed. Works even when public signups are disabled.
# NOTE: the ENV vars are the source of truth — every run RESETS the admin's
# password to MALADY_ADMIN_PASSWORD. Rotate the password by changing the env var,
# not the DB (a DB-only change is reverted on the next run).
class AdminProvisioner
  def initialize(env = ENV)
    @email = env["MALADY_ADMIN_EMAIL"].presence
    @password = env["MALADY_ADMIN_PASSWORD"].presence
  end

  # Returns the admin User, or nil if ENV is incomplete.
  def call
    return nil unless @email && @password

    user = User.find_or_initialize_by(email: @email)
    user.password = @password
    user.admin = true
    user.confirmed_at ||= Time.current # bypass email confirmation for the bootstrap admin
    user.save!
    user
  end
end
