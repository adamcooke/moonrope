require 'test/unit'
require 'rack/test'
require 'moonrope'

class Test::Unit::TestCase

  private

  def make_rack_env_hash(path, params = {}, other_env = {})
    request = Rack::Test::Session.new(nil)
    request.send :env_for, path, {:params => params, :method => 'POST'}.merge(other_env)
  end

end

#
# A fake base object for models
#
class ModelBase
  def initialize(attributes = {})
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end
end

class Animal < ModelBase
  attr_accessor :id, :name, :color, :user
end

class User < ModelBase
  attr_accessor :id, :username, :private_code, :admin
  def animals
    @animals ||= []
  end
end

class UserWithUnderscore < User
  class << self
    def name
      s = Struct.new(:underscore, :to_s).new
      s.to_s = 'User'
      s.underscore = 'user'
      s
    end
  end
end

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

  def identity
    @options[:identity]
  end

  def action
    nil
  end

end

#
# Require all tests
#
Dir[File.expand_path("../tests/**/*.rb", __FILE__)].each do |filename|
  require filename
end
