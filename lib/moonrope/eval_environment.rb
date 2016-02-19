require 'moonrope/eval_helpers'
require 'moonrope/eval_helpers/filter_helper'

module Moonrope
  class EvalEnvironment

    include Moonrope::EvalHelpers
    include Moonrope::EvalHelpers::FilterHelper

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
    def initialize(base, request, action = nil, accessors = {})
      @base = base
      @request = request
      @action = action
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
    def identity
      request ? request.identity : nil
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
    # @param structure_name [Moonrope::Structure or Symbol] the structure to be used
    # @param object [Object] the object to pass through the structure
    # @param options [Hash] options to pass to the strucutre hash generator
    #
    def structure(structure_name_or_object, object_or_options = {}, options_if_structure_name = {})

      if structure_name_or_object.is_a?(Symbol) || structure_name_or_object.is_a?(String) || structure_name_or_object.is_a?(Moonrope::Structure)
        structure_name = structure_name_or_object
        object = object_or_options
        options = options_if_structure_name
      elsif structure_name_or_object.class.name.respond_to?(:underscore)
        structure_name = structure_name_or_object.class.name.underscore.to_sym
        object = structure_name_or_object
        options = object_or_options
      else
        raise Moonrope::Errors::Error, "Could not determine structure name"
      end

      if object.nil?
        return nil
      end

      structure = structure_for(structure_name)

      unless structure.is_a?(Moonrope::Structure)
        raise Moonrope::Errors::Error, "No structure found named '#{structure_name}'"
      end

      if options.delete(:return)
        if options.empty? && action && action.returns && action.returns[:structure_opts].is_a?(Hash)
          options = action.returns[:structure_opts]
        end
      end

      if request
        if options[:paramable]
          if options[:paramable].is_a?(Hash)
            options[:expansions] = options[:paramable][:expansions]
            options[:full] = options[:paramable][:full]
          end

          if options[:paramable] == true || options[:paramable].is_a?(Hash) && options[:paramable].has_key?(:expansions)
            if request.params["_expansions"].is_a?(Array)
              options[:expansions] = request.params["_expansions"].map(&:to_sym)
              if options[:paramable].is_a?(Hash) && options[:paramable][:expansions].is_a?(Array)
                whitelist = options[:paramable][:expansions]
                options[:expansions].reject! { |e| !whitelist.include?(e) }
              end
            end

            if request.params["_expansions"] == true
              if options[:paramable].is_a?(Hash)
                if options[:paramable][:expansions].is_a?(Array)
                  options[:expansions] = options[:paramable][:expansions]
                elsif options[:paramable].has_key?(:expansions)
                  options[:expansions] = true
                end
              else
                options[:expansions] = true
              end
            end

            if request.params["_expansions"] == false
              options[:expansions] = nil
            end

          end

          if request.params.has?("_full")
            if options[:paramable] == true || (options[:paramable].is_a?(Hash) && options[:paramable].has_key?(:full))
              options[:full] = !!request.params["_full"]
            end
          end
        end
      end

      structure.hash(object, options.merge(:request => @request))
    end

    #
    # Return a Moonrope::Structure object for the provided name
    #
    # @param structure_name [Symbol or String] the structure to return
    #
    def structure_for(structure_name)
      structure = case structure_name
      when Symbol, String       then @base.structure(structure_name.to_sym)
      when Moonrope::Structure  then structure_name
      else
        false
      end
    end

    #
    # Return whether or not a given structure name is valid?
    #
    # @param structure_name [Symbol or String] the structure to return
    #
    def has_structure_for?(structure_name)
      self.structure_for(structure_name).is_a?(Moonrope::Structure)
    end

    #
    # Copy the list of parameters onto the given objectr
    #
    def copy_params_to(object, *params_to_copy)
      if params_to_copy.first.is_a?(Hash)
        options = params_to_copy.shift
        if options[:from]
          all_params = action.params.select { |_,p| p[:from_shared_action].include?(options[:from]) }
          params_to_copy = params_to_copy + all_params.keys
        end
      end
      params_to_copy.each do |param_name|
        if param_definition = action.params[param_name]
          if params.has?(param_name)
            if param_definition[:apply]
              instance_exec(object, params[param_name], &param_definition[:apply])
            elsif object.respond_to?("#{param_name}=")
              object.send("#{param_name}=", params[param_name])
            end
          end
        else
          raise Moonrope::Errors::Error, "Attempted to copy parameter #{parameter} to object but no definition exists"
        end
      end
    end

  end
end
