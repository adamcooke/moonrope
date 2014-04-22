require 'test/unit'
require 'moonrope'

#
# Load the example moonrope DSL
#
$mr = Moonrope::CoreDSL.load(File.expand_path('../app/moonrope', __FILE__))

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