# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'conveyor/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Will Fisher"]
  gem.email         = ["will@gina.alaska.edu"]
  gem.summary       = %q{GINA Data Conveyor}
  gem.description   = %q{Conveyor is used for shuffling data around}
  gem.homepage      = "http://github.com/gina-alaska/conveyor.git"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = %w{conveyor}
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "gina-conveyor"
  gem.require_paths = ["lib"]
  gem.version       = Conveyor::VERSION

  gem.add_dependency('activemodel', '~> 3.2.0')
  gem.add_dependency('activesupport', '~> 3.2.0')
  gem.add_dependency('listen', '~> 0.4.2')
  gem.add_dependency('rainbow', '~> 1.1.4')
  gem.add_dependency('rb-readline', '~> 0.4.2')
  gem.add_dependency('eventmachine', '~> 0.12.10')
  gem.add_dependency('em-websocket', '~> 0.3.6')
end
