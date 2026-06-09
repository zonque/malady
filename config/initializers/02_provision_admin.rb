# Auto-provision the admin account from MALADY_ADMIN_EMAIL / MALADY_ADMIN_PASSWORD
# on boot, so that simply setting those env vars and starting the app is enough to
# log in as the admin — no separate `rails db:seed` / `malady:ensure_admin` needed.
#
# - No-op when the env vars are unset.
# - Skipped in the test environment (avoids polluting the test database).
# - Skipped when the `users` table doesn't exist yet (fresh DB before migrate,
#   or `assets:precompile` with no database) — guarded so boot/precompile never
#   crashes. A bad admin password (below Devise's minimum) logs a warning rather
#   than aborting startup.
Rails.application.config.after_initialize do
  unless Rails.env.test?
    begin
      if ActiveRecord::Base.connection.data_source_exists?("users")
        if (admin = AdminProvisioner.new.call)
          Rails.logger.info("[Malady] Admin account ensured: #{admin.email}")
        end
      end
    rescue StandardError => e
      # DB unreachable (e.g. during precompile) or invalid admin password — don't
      # crash boot; surface the reason instead.
      Rails.logger.warn("[Malady] Skipped admin provisioning: #{e.class}: #{e.message}")
    end
  end
end
