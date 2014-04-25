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
    
    def initialize
      @dsl = Moonrope::DSL.new(self)
      @structures = []
      @controllers = []
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
    # Create a new rack request for this API
    #
    def request(*args)
      Rack::Request.new(self, *args)
    end
    
  end
end
