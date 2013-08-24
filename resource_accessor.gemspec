# -*- encoding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/lib/resource_accessor/version')

Gem::Specification.new do |spec|
  spec.name          = "resource_accessor"
  spec.summary       = %q{This library is used to simplify access to protected or unprotected http resource}
  spec.description   = %q{This library is used to simplify access to protected or unprotected http resource}
  spec.email         = "alexander.shvets@gmail.com"
  spec.authors       = ["Alexander Shvets"]
  spec.homepage      = "http://github.com/shvets/resource_accessor"

  spec.files         = `git ls-files`.split($\)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.version       = ResourceAccessor::VERSION
  spec.license       = "MIT"

  
  spec.add_development_dependency "gemspec_deps_gen", [">= 0"]
  spec.add_development_dependency "gemcutter", [">= 0"]

end

