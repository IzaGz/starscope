require File.expand_path('../lib/starscope/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'starscope'
  gem.version       = StarScope::VERSION
  gem.summary       = "A code indexer and analyzer"
  gem.description   = "A tool like the venerable cscope, but for ruby and other languages"
  gem.authors       = ["Evan Huus"]
  gem.homepage      = 'https://github.com/eapache/starscope'
  gem.email         = 'eapache@gmail.com'
  gem.files         = `git ls-files`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency 'parser', '~> 1.4'
  gem.add_development_dependency 'bundler', '~> 1.3'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-debugger'
end