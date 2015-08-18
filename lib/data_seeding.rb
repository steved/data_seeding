module DataSeeding
  class Rollback < StandardError; end
  module Commands
    def rollback
      throw(:rollback, true)
    end
  end

  class Railtie < Rails::Railtie
    dirname = File.expand_path(File.dirname(__FILE__))
    rake_tasks do
      load File.join(dirname, 'tasks/seeding.rake')
    end
  end
end
