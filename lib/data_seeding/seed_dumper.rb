require 'fileutils'
require 'docker'

module DataSeeding
  class SeedDumper
    attr_reader :configuration, :file, :options

    def initialize(configuration, file, options = {})
      @configuration, @file, @options = configuration, file, options
    end

    def dump_seed
      FileUtils.mkdir_p(File.dirname(file))

      # Mostly stolen from https://github.com/rails/rails/blob/4-2-stable/activerecord/lib/active_record/tasks/mysql_database_tasks.rb
      args = ['mysqldump']

      args.concat(['--user', configuration['username']]) if configuration['username']
      args.concat(['--default-character-set', configuration['encoding']]) if configuration['encoding']

      args << "--password=#{configuration['password']}" if configuration['password']

      configuration.slice('host', 'port', 'socket').each do |k, v|
        args.concat(["--#{k}", v.to_s]) if v
      end

      # End stealing

      args.concat(['--ignore-table', "#{configuration['database']}.schema_migrations"])
      options.fetch(:ignore_tables, []).each do |table|
        args.concat(['--ignore-table', "#{configuration['database']}.#{table}"])
      end

      args << '-t' # skips structure
      args << '--compact'
      args << '--skip-extended-insert'
      args << '--complete-insert'
      args << '--disable-keys'

      args.concat(['--result-file', file.to_s])
      args << configuration['database']

      unless Kernel.system(*args)
        $stderr.puts "An error occurred trying to dump the seed file to #{file}"
      end
    end

    def dump_docker_data
      return unless options[:docker_data]

      image = Docker::Image.create('fromImage' => 'busybox', 'Cmd' => %w{true})

      options[:docker_data].each do |path|
        image = image.insert_local('localPath' => path.to_s, 'outputPath' => "/#{File.basename(path)}")
      end

      puts "Built #{image.id} from #{options[:docker_data].join(', ')}"
    end
  end
end
