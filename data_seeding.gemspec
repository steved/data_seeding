Gem::Specification.new do |gem|
  gem.name = 'data_seeding'
  gem.version = '0.0.1'
  gem.authors = ['Steven Davidovitz']
  gem.email = ['steven.davidovitz@gmail.com']
  gem.summary = gem.description = 'Interactive data seeds'

  gem.add_dependency 'ripl'
  gem.add_dependency 'docker-api'
end
