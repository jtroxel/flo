# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Troxel"]
  gem.email         = ["jtroxel@yahoo.com"]
  gem.description   = %q{Flo: a simple library for composing extensible multi-step procedures}
  gem.summary       = %q{Easily define flows--directed graphs of pluggable steps with a fluent interface:  http://www.codecraftblog.com/2012/08/building-procedures-with-composition.html}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "flo"
  gem.require_paths = ["lib"]
  gem.version       = Flo::VERSION

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rubytree"

end
