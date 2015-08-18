require_relative 'data_seeding/commands'
require_relative 'data_seeding/seed_dumper'
require_relative 'data_seeding/seed_loader'
require_relative 'data_seeding/rollback'

module DataSeeding
  module Config
    class << self
      attr_writer :path, :ignore_tables

      def path
        @path ||= Rails.application.root.join('db/seeds/data.sql')
      end

      def ignore_tables
        @ignore_tables ||= []
      end
    end
  end

  module LoadSeed
    def load_seed
      DataSeeding::SeedLoader.new(
        database_configuration,
        DataSeeding::Config.path
      ).load_seed
    end
  end

  extend LoadSeed

  class << self
    # These methods are for Rails 3 compatibility
    def database_configuration
      config_base = if defined?(ActiveRecord::Tasks::DatabaseTasks)
        ActiveRecord::Tasks::DatabaseTasks
      else
        Rails.application.config
      end

      config_base.database_configuration['development']
    end

    def set_seed_loader
      if defined?(ActiveRecord::Tasks::DatabaseTasks)
        ActiveRecord::Tasks::DatabaseTasks.seed_loader = DataSeeding
      else
        Rails.application.class.prepend(DataSeeding::LoadSeed)
      end
    end
  end
end

if defined?(Rails)
  require_relative 'data_seeding/railtie'
end
