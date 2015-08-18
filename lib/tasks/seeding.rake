require 'ripl'

task 'db:seed' => ['seed:set_loader']

namespace :seed do
  task set_loader: ['db:load_config'] do
    ActiveRecord::Tasks::DatabaseTasks.seed_loader = DataSeeding::SeedLoader.new(
      ActiveRecord::Tasks::DatabaseTasks.database_configuration['development'],
      Rails.application.root.join('db/seeds/data.sql')
    )
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
        rollback = catch(:rollback) do
          Ripl.start(argv: [])
        end

        if rollback
          raise(DataSeeding::Rollback, 'user requested rollback')
        end
      end
    rescue DataSeeding::Rollback
      puts 'Rolling back to original state.'
      retry
    end

    rake_task = Rake.application.lookup('seed:dump', t.scope)
    rake_task.invoke
    rake_task.reenable

    rake_task = Rake.application.lookup('db:drop', t.scope)
    rake_task.invoke
    rake_task.reenable
  end

  desc 'Dump the current version of your database data'
  task dump: ['db:load_config'] do
    DataSeeding::SeedDumper.new(
      ActiveRecord::Tasks::DatabaseTasks.database_configuration['development'],
      Rails.application.root.join('db/seeds/data.sql')
    ).dump_seed
  end
end
