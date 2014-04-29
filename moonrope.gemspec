$:.push File.expand_path("../lib", __FILE__)

require "moonrope/version"

Gem::Specification.new do |s|
  s.name        = "moonrope"
  s.version     = Moonrope::VERSION
  s.authors     = ["Adam Cooke"]
  s.email       = ["adam@viaduct.io"]
  s.homepage    = "http://viaduct.io"
  s.summary     = "An API server DSL."
  s.description = "A full library allowing you to create sexy DSLs to define your RPC-like APIs."
  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.add_dependency "json", "~> 1.8.1"
  s.add_dependency "rack", "~> 1.5.0"
  s.add_development_dependency "rake", '~> 10.3.1'
  s.add_development_dependency "test-unit", '~> 2.5.5'
  s.add_development_dependency 'yard', '~> 0.8.7'
  s.add_development_dependency "rack-test"
end
