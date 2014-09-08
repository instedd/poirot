# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hercule/version'

Gem::Specification.new do |gem|
  gem.name          = "hercule"
  gem.version       = Hercule::VERSION
  gem.authors       = ["Gustavo Giraldez"]
  gem.email         = ["ggiraldez@manas.com.ar"]
  gem.description   = %q{}
  gem.summary       = %q{}
  gem.homepage      = "https://github.com/instedd/poirot"

  gem.add_dependency 'elasticsearch'

  gem.files         = Dir["lib/hercule/*"] + ["lib/hercule.rb"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end

