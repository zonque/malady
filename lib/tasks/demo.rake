namespace :malady do
  desc "Seed fake demo metrics + data points for a user (Faker). " \
       "Usage: bin/rails 'malady:demo_data' -- --email=EMAIL [--days=N] [--per-day=N] [--create]"
  # The positional [:email] form is kept for back-compat; --flags override it.
  task :demo_data, [ :email ] => :environment do |_t, args|
    require "optparse"

    opts = { email: args[:email], days: 60, per_day: 2, create: false }
    parser = OptionParser.new do |o|
      o.banner = "Usage: bin/rails 'malady:demo_data' -- --email=EMAIL [--days=N] [--per-day=N] [--create]"
      o.on("--email=EMAIL", "Target user email") { |v| opts[:email] = v }
      o.on("--days=N", Integer, "Days of history to generate (default 60)") { |v| opts[:days] = v }
      o.on("--per-day=N", Integer, "Data points per day per metric (default 2)") { |v| opts[:per_day] = v }
      o.on("--create", "Create a confirmed user if one doesn't exist") { opts[:create] = true }
    end

    # Rake doesn't parse `--foo=bar`; take the tokens after the task name (and an
    # optional `--` separator) and parse them ourselves.
    task_idx = ARGV.index { |a| a.include?("demo_data") } || -1
    rest = ARGV[(task_idx + 1)..] || []
    rest = rest.drop(1) if rest.first == "--"
    parser.parse!(rest)

    email = opts[:email].presence || ENV["MALADY_DEMO_EMAIL"].presence || "demo@malady.test"

    user = User.find_by(email: email)
    if user.nil? && opts[:create]
      user = User.create!(
        email: email,
        password: ENV.fetch("MALADY_DEMO_PASSWORD", "password123"),
        confirmed_at: Time.current
      )
      puts "Created confirmed user #{email}."
    end

    unless user
      warn "No user with email #{email}. Pass --create to make one, or use a valid email."
      exit 1
    end

    DemoDataGenerator.new(user, days: opts[:days], per_day: opts[:per_day]).generate!
    points = DataPoint.where(metric: user.metrics).count
    puts "Demo data ready for #{email}: #{user.metrics.count} metrics, #{points} data points " \
         "(#{opts[:days]} days × #{opts[:per_day]}/day)."

    # Stop Rake from treating the parsed flags (still in ARGV) as task names.
    exit 0
  end
end
