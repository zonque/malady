namespace :malady do
  desc "Generate Faker demo metrics + data points (email arg or MALADY_DEMO_EMAIL, default demo@malady.test)"
  task :demo_data, [ :email ] => :environment do |_t, args|
    email = args[:email] || ENV.fetch("MALADY_DEMO_EMAIL", "demo@malady.test")
    user = User.find_by(email: email)
    abort "No user with email #{email}. Create one or pass a valid email." unless user
    DemoDataGenerator.new(user).generate!
    points = DataPoint.where(metric: user.metrics).count
    puts "Demo data ready for #{email}: #{user.metrics.count} metrics, #{points} data points."
  end
end
