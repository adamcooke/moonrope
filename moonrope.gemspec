$:.push File.expand_path("../lib", __FILE__)

require "moonrope/version"

Gem::Specification.new do |s|
  s.name        = "moonrope"
  s.version     = Moonrope::VERSION
  s.authors     = ["Adam Cooke"]
  s.email       = ["adam@atechmedia.com"]
  s.homepage    = "http://adamcooke.io"
  s.licenses    = ['MIT']
  s.summary     = "An API server DSL."
  s.description = "A full library allowing you to create sexy DSLs to define your RPC-like APIs."
  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.add_dependency "json", "~> 1.7"
  s.add_dependency "rack", "~> 1.4"
  s.add_development_dependency "rake", '~> 10.3'
  s.add_development_dependency "test-unit", '~> 2.5'
  s.add_development_dependency 'yard', '~> 0.8'
  s.add_development_dependency "rack-test", '~> 0'
end
