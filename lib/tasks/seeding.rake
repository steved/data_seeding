require 'ripl'

namespace :data_seeding do
  task :seed do
  end

  namespace :seed do
    task edit: [:environment, 'db:load_config'] do |t|
      configuration = ActiveRecord::Tasks::DatabaseTasks.database_configuration['development'].dup
      configuration['database'] = SecureRandom.hex(8)

      ActiveRecord::Tasks::DatabaseTasks.create(configuration)
      ActiveRecord::Base.establish_connection(configuration)
      ActiveRecord::Tasks::DatabaseTasks.load_schema_for(configuration, ActiveRecord::Base.schema_format, ActiveRecord::Tasks::DatabaseTasks.schema_file)

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
    end
  end
end
