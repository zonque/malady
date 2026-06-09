module Malady
  # Fail-closed allowlist: only explicit truthy values open signups, so a typo
  # in the env var (e.g. "ture") leaves registration CLOSED rather than open.
  SIGNUP_TRUTHY = %w[true 1 yes on].freeze

  def self.signups_allowed?
    SIGNUP_TRUTHY.include?(ENV.fetch("MALADY_ALLOW_SIGNUPS", "false").to_s.strip.downcase)
  end
end
