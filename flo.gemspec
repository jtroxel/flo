# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Troxel"]
  gem.email         = ["jtroxel@yahoo.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
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
