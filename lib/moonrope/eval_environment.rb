module Moonrope
  class EvalEnvironment
    
    attr_reader :base, :variables, :request
    attr_accessor :default_params
    
    def initialize(base, request, accessors = {})
      @base = base
      @request = request
      @accessors = accessors
      @variables = {}
      @default_params = {}
      reset
    end
    
    #
    # Return the version of the API which has been requested
    #
    def version
      request ? request.version : 1
    end
    
    #
    # Return the auth'd object
    #
    def auth
      request ? request.authenticated_user : nil
    end
    
    #
    # Return the parameters for the request
    #
    def params
      @params ||= begin
        params = request ? request.params : ParamSet.new
        params._defaults = @default_params
        params
      end
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
    # Raise an error
    #
    def error(type, message)
      case type
      when :not_found           then raise(Moonrope::Errors::NotFound, message)
      when :access_denied       then raise(Moonrope::Errors::AccessDenied, message)
      when :validation_error    then raise(Moonrope::Errors::ValidationError, message)
      when :parameter_error     then raise(Moonrope::Errors::ParameterError, message)
      else
        raise Moonrope::Errors::RequestError, message
      end
    end
    
    #
    # Return an accessor if that's possible
    #
    def method_missing(name, value = nil)
      if @accessors.keys.include?(name.to_sym)
        @accessors[name.to_sym]
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
      if object && structure = @base.structure(structure)
        structure.hash(object, options.merge(:request => @request))
      else
        nil
      end
    end
    
  end
end
