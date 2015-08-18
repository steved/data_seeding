module DataSeeding
  class Railtie < Rails::Railtie
    dirname = File.expand_path(File.dirname(__FILE__))

    rake_tasks do
      load File.join(dirname, 'tasks.rb')
    end
  end
end
