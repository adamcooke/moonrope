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
      api.load(path)
      api
    end
    
    # @return [Array] the array of defined structures
    attr_reader :structures
    
    # @return [Array] the array of defined controllers
    attr_accessor :controllers
    
    # @return [Array] the array of defined helpers
    attr_accessor :helpers
    
    # @return [Moonrope::DSL::BaseDSL] the base DSL
    attr_accessor :dsl
    
    # @return [Proc] the authentictor
    attr_accessor :authenticator
    
    # @return [Proc] the default access condition
    attr_accessor :default_access
    
    # @return [String] the directory the base was loaded from (if relevant)
    attr_accessor :loaded_from
    
    #
    # Initialize a new instance of the Moonrope::Base
    #
    # @yield instance evals the contents within the Base DSL
    #
    def initialize(&block)
      unload
      @dsl = Moonrope::DSL::BaseDSL.new(self)
      @dsl.instance_eval(&block) if block_given?
    end
    
    #
    # Reset the whole base to contain no data.
    #
    def unload
      @structures = []
      @controllers = []
      @helpers = @helpers.is_a?(Array) ? @helpers.select { |h| h.options[:unloadable] == false } : []
      @authenticator = nil
      @default_access = nil
    end
    
    #
    # Reload this whole base API from the path
    #
    def load(directory = nil)
      directory = self.loaded_from if directory.nil?
      if directory
        unload
        Dir["#{directory}/**/*.rb"].each do |filename|
          self.dsl.instance_eval(File.read(filename), filename)
        end
        self.loaded_from = directory
        self
      else
        raise Moonrope::Errors::Error, "Can't reload Moonrope::Base as it wasn't required from a directory"
      end
    end
    
    alias_method :reload, :load
    
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
    
    #
    # Return a helper for the given name and, potentially controller
    #
    # @param name [Symbol] the name of the helper
    # @param controller [Moonrope::Controller] the controller scope
    #
    def helper(name, controller = nil)
      if controller
        matched_helpers = @helpers.select do |h|
          h.name == name.to_sym && (h.controller.nil? || h.controller == controller)
        end
      else
        matched_helpers = @helpers.select { |h| h.name == name.to_sym && h.controller.nil? }
      end
      matched_helpers.first
    end
    
    #
    # Return all the external errors which are registered for this base
    #
    # @return [Hash] a hash of external errors
    #
    def external_errors
      @external_errors ||= {}
    end
    
    #
    # Register a new external error
    #
    # @param error_class [Class] a class which should be caught 
    #
    def register_external_error(error_class, &block)
      self.external_errors[error_class] = block
    end
    
  end
end
