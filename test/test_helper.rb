require 'test/unit'
require 'rack/test'
require 'moonrope'

#
# Load the example moonrope DSL
#
$mr = Moonrope::Base.load(File.expand_path('../app/moonrope', __FILE__))

# 
# Require models
#
Dir[File.expand_path("../app/models/**/*.rb", __FILE__)].each do |filename|
  require filename
end

#
# Require all tests
#
Dir[File.expand_path("../tests/**/*.rb", __FILE__)].each do |filename|
  require filename
end

