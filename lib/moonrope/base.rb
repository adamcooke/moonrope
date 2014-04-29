module Moonrope
  class Base
        
    def self.load(path)
      api = self.new
      Dir["#{path}/**/*.rb"].each do |filename|
        api.dsl.instance_eval(File.read(filename), filename)
      end
      api
    end
    
    attr_reader :structures, :controllers, :dsl
    attr_accessor :authenticator, :default_access
    
    def initialize(&block)
      @structures = []
      @controllers = []
      @authenticator = nil
      @default_access = nil
      @dsl = Moonrope::DSL::BaseDSL.new(self)
      @dsl.instance_eval(&block) if block_given?
    end
    
    #
    # Return a structure of the given name
    #
    def structure(name)
      structures.select { |s| s.name == name }.first
    end
    
    #
    # Return a controller of the given name
    #
    def controller(name)
      controllers.select { |a| a.name == name }.first
    end
    
    #
    # Shorthand for requesting a controller
    #
    def /(name)
      controller(name)
    end
    
    #
    # Create a new rack request for this API
    #
    def request(*args)
      Moonrope::Request.new(self, *args)
    end
    
  end
end
