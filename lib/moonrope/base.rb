module Moonrope
  class Base
    
    #
    # Load a set of Moonrope configuration files from a given 
    # directory.
    #
    # @param path [String] the path to a directory containing Moonrope files
    # @return [Moonrope::Base]
    #
    def self.load(path)
      api = self.new
      Dir["#{path}/**/*.rb"].each do |filename|
        api.dsl.instance_eval(File.read(filename), filename)
      end
      api
    end
    
    # @return [Array] the array of defined structures
    attr_reader :structures
    
    # @return [Array] the array of defined controllers
    attr_accessor :controllers
    
    # @return [Moonrope::DSL::BaseDSL] the base DSL
    attr_accessor :dsl
    
    # @return [Proc] the authentictor
    attr_accessor :authenticator
    
    # @return [Proc] the default access condition
    attr_accessor :default_access
    
    #
    # Initialize a new instance of the Moonrope::Base
    #
    # @yield instance evals the contents within the Base DSL
    #
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
    # @param name [Symbol] the name of the structure
    # @return [Moonrope::Structure]
    #
    def structure(name)
      structures.select { |s| s.name == name }.first
    end
    
    alias_method :[], :structure
    
    #
    # Return a controller of the given name
    #
    # @param name [Symbol] the name of the controller
    # @return [Moonrope::Controller]
    #
    def controller(name)
      controllers.select { |a| a.name == name }.first
    end
    
    alias_method :/, :controller
    
    #
    # Create a new rack request for this API.
    #
    # @return [Moonrope::Request] a new request object
    #
    def request(*args)
      Moonrope::Request.new(self, *args)
    end
    
  end
end
