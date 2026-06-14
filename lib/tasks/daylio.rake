namespace :malady do
  desc "Import a Daylio CSV export for a user. " \
       "Usage: bin/rails 'malady:import_daylio' -- --user=EMAIL_OR_ID --file=PATH [--dry-run]"
  task import_daylio: :environment do
    require "optparse"

    opts = { dry_run: false }
    parser = OptionParser.new do |o|
      o.banner = "Usage: bin/rails 'malady:import_daylio' -- --user=EMAIL_OR_ID --file=PATH [--dry-run]"
      o.on("--user=USER", "Target user (email or numeric id)") { |v| opts[:user] = v }
      o.on("--file=FILE", "Path to the Daylio CSV export") { |v| opts[:file] = v }
      o.on("--dry-run", "Parse and report without writing anything") { opts[:dry_run] = true }
    end

    # Rake doesn't parse `--foo=bar`; take the tokens after the task name (and an
    # optional `--` separator) and parse them ourselves.
    task_idx = ARGV.index { |a| a.include?("import_daylio") } || -1
    rest = ARGV[(task_idx + 1)..] || []
    rest = rest.drop(1) if rest.first == "--"
    parser.parse!(rest)

    if opts[:user].blank? || opts[:file].blank?
      warn parser
      exit 1
    end

    user = User.find_by(id: Integer(opts[:user], exception: false)) ||
           User.find_by(email: opts[:user])
    unless user
      warn "No user matching #{opts[:user].inspect} (try an email or numeric id)."
      exit 1
    end

    unless File.exist?(opts[:file])
      warn "File not found: #{opts[:file]}"
      exit 1
    end

    logger = Logger.new($stdout)
    logger.formatter = ->(_severity, _time, _progname, msg) { "#{msg}\n" }
    logger.info "Importing #{opts[:file]} for #{user.email} (id #{user.id})#{' [dry-run]' if opts[:dry_run]}"

    begin
      daylio_export = Daylio::CsvExport.read(opts[:file])
    rescue Daylio::CsvExport::Error => e
      warn "Could not read Daylio CSV: #{e.message}"
      exit 1
    end

    DaylioImporter.new(user: user, export: daylio_export, dry_run: opts[:dry_run], logger: logger).import!

    # Stop Rake from treating the parsed flags (still in ARGV) as task names.
    exit 0
  end
end
