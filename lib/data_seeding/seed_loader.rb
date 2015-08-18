module DataSeeding
  class SeedLoader
    attr_reader :configuration, :file

    def initialize(configuration, file)
      @configuration, @file = configuration, file
    end

    def load_seed
      # TODO check file exist

      args = ['mysql']

      args.concat(['--user', configuration['user']]) if configuration['user']

      # ??
      args.concat(['--default-character-set', configuration['encoding']]) if configuration['encoding']

      args << "--password=#{configuration['password']}" if configuration['password']

      configuration.slice('host', 'port', 'socket').each do |k, v|
        args.concat(["--#{k}", v.to_s]) if v
      end

      args.concat(['-e', "SOURCE #{file}"])

      args << configuration['database']

      unless Kernel.system(*args)
        raise 'well, shit'
      end
    end
  end
end
