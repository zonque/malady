namespace :malady do
  desc "Ensure the admin account exists (from MALADY_ADMIN_EMAIL / MALADY_ADMIN_PASSWORD)"
  task ensure_admin: :environment do
    user = AdminProvisioner.new.call
    puts user ? "Admin ensured: #{user.email}" : "MALADY_ADMIN_EMAIL/PASSWORD not set; no admin provisioned."
  end
end
