require 'ripl'

task 'db:seed' => ['seed:set_loader']

namespace :seed do
  task set_loader: ['db:load_config'] do
    DataSeeding.set_seed_loader
  end

  task :randomize_database_name do
    configuration = ActiveRecord::Tasks::DatabaseTasks.database_configuration['development']
    configuration['database'] = SecureRandom.hex(8)
    puts "Using database '#{configuration['database']}'."
  end

  task :set_env do
    # Rails likes to check this and create a test DB
    ENV['RAILS_ENV'] = 'development'
  end

  desc 'Interactively edit your data seeds'
  task edit: [:environment, 'db:load_config', :set_env, :randomize_database_name, 'db:create', 'db:structure:load', 'db:seed'] do |t|
    Ripl::Commands.include(DataSeeding::Commands)

    begin
      ActiveRecord::Base.transaction do
        retval = catch(:rollback) do
          Ripl.start(argv: [])
        end

        if retval == :rollback
          raise(DataSeeding::Rollback, 'user requested rollback')
        end
      end
    rescue DataSeeding::Rollback
      puts 'Rolling back to original state.'
      retry
    end

    Rake.application.lookup('seed:dump', t.scope).invoke
    Rake.application.lookup('db:drop', t.scope).invoke
  end

  desc 'Dump the current version of your database data'
  task dump: ['db:load_config'] do
    DataSeeding::SeedDumper.new(
      DataSeeding.database_configuration,
      DataSeeding::Config.path,
      ignore_tables: DataSeeding::Config.ignore_tables
    ).dump_seed
  end
end
