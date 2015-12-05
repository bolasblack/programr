# -*- encoding: utf-8 -*-
require File.expand_path('../lib/programr/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mauro Cicio, Nicholas H.Tollervey, Ben Minton, Robert J Whitney, c4605"]
  gem.email         = ["bolasblack@gmail.com"]
  gem.description   = %q{Ruby interpreter for the AIML}
  gem.summary       = %q{ProgramR is a Ruby implementation of an interpreter for the Artificial Intelligence Markup Language (AIML) based on the work of Dr. Wallace and defined by the Alicebot and AIML Architecture Committee of the A.L.I.C.E. AI Foundation (http://alicebot.org}
  gem.homepage      = "https://github.com/bolasblack/programr"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "programr"
  gem.require_paths = ["lib"]
  gem.version       = Programr::VERSION

  gem.add_development_dependency 'singleton.new', '~> 0.0.2'
  gem.add_development_dependency 'rspec', '~> 3.2.0'
  gem.add_development_dependency 'pry', '~> 0.10.1'
  gem.add_development_dependency 'yard', '~> 0.8.7.6'
  gem.add_dependency 'activesupport', '~> 4.1.8'
end
