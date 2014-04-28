module Moonrope
  class EvalEnvironment
    
    attr_reader :base, :request, :headers, :flags
    attr_accessor :default_params
    
    def initialize(base, request, accessors = {})
      @base = base
      @request = request
      @accessors = accessors
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
    # Provide access to set some return headers for the request.
    # Does not permit reading the 
    #
    def set_header(name, value)
      @headers[name.to_s] = value
    end
    
    #
    # Provide access to set some return headers for the request.
    # Does not permit reading the 
    #
    def set_flag(name, value)
      @flags[name] = value
    end
    
    # 
    # Reset the variables which change during runtime for this eval environment
    #
    def reset
      @flags = {}
      @headers = {}
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
      if object
        structure = case structure
        when Symbol, String       then @base.structure(structure.to_sym)
        when Moonrope::Structure  then structure
        else
          raise Moonrope::Errors::Error, "Invalid structure '#{structure}'"
        end
        if structure
          structure.hash(object, options.merge(:request => @request))
        else
          raise Moonrope::Errors::Error, "No structure found named '#{structure}'"
        end
      else
        nil
      end
    end
    
  end
end
