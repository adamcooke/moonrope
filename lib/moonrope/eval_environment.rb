module Moonrope
  class EvalEnvironment
    
    attr_reader :core_dsl, :variables
    
    def initialize(core_dsl, params = {})
      @core_dsl = core_dsl
      @params = params
      reset
    end
    
    #
    # Return the version of the API which has been requested
    #
    def version
      Moonrope.globals[:version] || 1
    end
    
    #
    # Return the authenticated user
    #
    def auth
      Moonrope.globals[:auth]
    end
    
    #
    # Return the globals
    #
    def globals
      Moonrope.globals
    end
    
    #
    # Set a variable
    #
    def set(name, value = nil)
      @variables[name] = value
    end
    
    # 
    # Reset the variables for this eval environment
    #
    def reset
      @variables = {}
    end
    
    #
    # Method missing
    #
    def method_missing(key, value = nil)
      if @params.keys.include?(key)
        @params[key]
      else
        super
      end
    end
    
    #
    # Generate a new structure from the core DSL for the given
    # object and return a hash or nil if the structure doesn't 
    # exist.
    #
    def structure(structure, object, options = {})
      if object && structure = @core_dsl.structure(structure)
        structure.hash(object, options)
      else
        nil
      end
    end
    
  end
end
