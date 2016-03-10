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
  s.files = Dir["**/*"]
  s.bindir = "bin"
  s.executables << 'moonrope'
  s.add_dependency "json", "~> 1.7"
  s.add_dependency "rack", ">= 1.4"
  s.add_dependency "deep_merge", "~> 1.0"
  s.add_development_dependency "rake", '~> 10.3'
end
