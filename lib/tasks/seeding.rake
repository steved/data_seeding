require 'ripl'

task 'db:seed' => ['data_seeding:set_seed_loader']

namespace :data_seeding do
  task :set_seed_loader do
    ActiveRecord::Tasks::DatabaseTasks.seed_loader = DataSeeding::SeedLoader.new(
      ActiveRecord::Tasks::DatabaseTasks.database_configuration['development'],
      Rails.application.root.join('db/seeds/data.sql')
    )
  end

  namespace :seed do
    task edit: [:environment, 'db:load_config'] do |t|
      # Rails likes to check this and create a test DB
      ENV['RAILS_ENV'] = 'development'

      configuration = ActiveRecord::Tasks::DatabaseTasks.database_configuration['development']
      configuration['database'] = SecureRandom.hex(8)

      puts "Using database '#{configuration['database']}'."

      silence_stream(STDOUT) do
        ActiveRecord::Tasks::DatabaseTasks.create_current
        ActiveRecord::Tasks::DatabaseTasks.load_schema_current
      end

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

      rake_task = Rake.application.lookup('data_seeding:seed:dump', t.scope)
      rake_task.invoke
      rake_task.reenable
    end

    task :dump do
      DataSeeding::DataDump.data_dump(
        ActiveRecord::Tasks::DatabaseTasks.current_config,
        Rails.application.root.join('db/seeds/data.sql')
      )
    end
  end
end
