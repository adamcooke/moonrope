module Moonrope
  class EvalEnvironment
    
    include Moonrope::EvalHelpers
    
    # @return [Moonrope::Base] the base object
    attr_reader :base
    
    # @return [Moonrope::Request] the associated request
    attr_reader :request
    
    # @return [Hash] the headers
    attr_reader :headers
    
    # @return [Hash] the flags
    attr_reader :flags
    
    # @return [Hash] the default params to be merged with request params
    attr_accessor :default_params
    
    # @return [Moonrope::Action] the action which invoked this environment
    attr_accessor :action
    
    #
    # Initialize a new EvalEnvironment
    #
    # @param base [Moonrope::Base]
    # @param request [Moonrope::Request]
    # @param accessors [Hash] additional variables which can be made available
    #
    def initialize(base, request, accessors = {})
      @base = base
      @request = request
      @accessors = accessors
      @default_params = {}
      reset
    end
    
    #
    # @return [Integer] the requested API version
    #
    def version
      request ? request.version : 1
    end
    
    #
    # @return [Object] the authenticated object
    #
    def auth
      request ? request.authenticated_user : nil
    end
    
    #
    # @return [Hash] all parameters sent for this request including defaults
    #
    def params
      @params ||= begin
        params = request ? request.params : ParamSet.new
        params._defaults = @default_params
        params
      end
    end
    
    #
    # Set a header which should be returned to the client.
    #
    # @param name [String] the key
    # @param value [String] the value
    # @return [void]
    #
    def set_header(name, value)
      @headers[name.to_s] = value
    end
    
    #
    # Set a flag which should be returned to the client.
    #
    # @param name [Symbol] the key
    # @param value [String] the value
    # @return [void]
    #
    def set_flag(name, value)
      @flags[name] = value
    end
    
    # 
    # Clear all flags & headers from this environment.
    # 
    # @return [void]
    #
    def reset
      @flags = {}
      @headers = {}
    end
    
    #
    # Attempts to find an return an accessor from the has
    #
    # @param name [Symbol] the name of the method
    # @param value [void] unused/wnated
    # @return [Object]
    #
    def method_missing(name, *args)
      if @accessors.keys.include?(name.to_sym)
        @accessors[name.to_sym]
      elsif helper = @base.helper(name.to_sym, action ? action.controller : nil)
        instance_exec(*args, &helper.block)
      else
        super
      end
    end
    
    #
    # Generate a new structure from the core DSL for the given
    # object and return a hash or nil if the structure doesn't 
    # exist.
    #
    # @param structure [Moonrope::Structure or Symbol] the structure to be used
    # @param object [Object] the object to pass through the structure
    # @param options [Hash] options to pass to the strucutre hash generator
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
