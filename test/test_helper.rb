require 'test/unit'
require 'rack/test'
require 'moonrope'

#
# Load the example moonrope DSL
#
$mr = Moonrope::Base.load(File.expand_path('../app/moonrope', __FILE__))

#
# A fake request class for use in some tests
#
class FakeRequest
  
  def initialize(options = {})
    @options = options
  end
  
  def params
    @params ||= Moonrope::ParamSet.new(@options[:params] || {})
  end
  
  def version
    @options[:version]
  end
  
  def authenticated_user
    @options[:authenticated_user]
  end
  
end

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
