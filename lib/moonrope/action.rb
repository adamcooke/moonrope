require 'moonrope/dsl/action_dsl'
require 'moonrope/action_result'

module Moonrope
  class Action

    # @return [Moonrope::Controller] the associated controller
    attr_reader :controller

    # @return [Symbol] the name of the action
    attr_reader :name

    # @return [Moonrope::DSL::Action] the action's DSL
    attr_reader :dsl

    # @return [Hash] the params available for the action
    attr_reader :params

    # @return [String] the title of the action
    attr_accessor :title

    # @return [String] the description of the action
    attr_accessor :description

    # @return [Array] the actual action blocks for the action
    attr_accessor :actions

    # @return [Symbol] the name of the authenticator for this action
    attr_accessor :authenticator

    # @return [Symbol] the name of the access rule for this action
    attr_accessor :access_rule

    # @return [Hash] the errors which can be retuend by this action
    attr_accessor :errors

    # @return [Hash] details of what will be returned on success
    attr_accessor :returns

    # @return [Bool] whether or not the action should be documented
    attr_accessor :doc

    # @return [Array] additional traits that have been applied to this action
    attr_reader :traits

    # @return [Hash] a hash of filters that are applied
    attr_reader :filters

    #
    # Initialize a new action
    #
    # @param controller [Moonrope::Controller] the controller this action belongs to
    # @param name [Symbol] the name of the action
    # @yield allows the action to be configured via Moonrope::DSL::ActionDSL
    #
    def initialize(controller, name, &block)
      @controller = controller
      @name = name
      @params = {}
      @errors = {}
      @traits = []
      @actions = []
      @filters = {}
      @dsl = Moonrope::DSL::ActionDSL.new(self)
      @dsl.instance_eval(&block) if block_given?
    end

    #
    # Return a hash of all params for this action which are
    #
    # @return [Hash] hash with field names as keys with default values
    #
    def default_params
      @params.inject({}) do |h,(k,v)|
        h[k.to_s] = v[:default] if v[:default]
        h
      end
    end

    #
    # Return the authenticator that should be used when executing this action
    #
    # @return [Moonrope::Authenticator]
    #
    def authenticator_to_use
      @authenticator_to_use ||= begin
        if @authenticator
          @controller.base.authenticators[@authenticator] || :not_found
        elsif @controller.authenticator
          @controller.base.authenticators[@controller.authenticator] || :not_found
        else
          @controller.base.authenticators[:default] || :none
        end
      end
    end

    #
    # Return the access rule to use for this action#
    #
    # @return [Symbol]
    #
    def access_rule_to_use
      @access_rule_to_use ||= access_rule || @controller.access_rule || :default
    end

    #
    # Execute a block of code and catch approprite Moonrope errors and return
    # a result.
    #
    def convert_errors_to_action_result(start_time = nil, &block)
      begin
        yield block
      rescue => exception
        case exception
        when Moonrope::Errors::RequestError
          result = ActionResult.new(self)
          result.time = start_time ? (Time.now - start_time).round(2) : nil
          result.status = exception.status
          result.data = exception.data
          result
        else
          if error_block = @controller.base.external_errors[exception.class]
            result = ActionResult.new(self)
            result.time = start_time ? (Time.now - start_time).round(2) : nil
            error_block.call(exception, result)
            result
          else
            raise
          end
        end
      end
    end

    #
    # Executes the action and returns a ActionResult object with the result
    # of the action.
    #
    # @param request [Moonrope::Request or Moonrope::EvalEnvironment]
    # @return [Moonrope::ActionResult]
    #
    def execute(request = nil)
      if request.is_a?(EvalEnvironment)
        eval_environment = request
      else
        eval_environment = EvalEnvironment.new(@controller.base, request, self)
      end

      #
      # Set this actions default parameters in the eval environment so that
      # it has access to them.
      #
      eval_environment.default_params = self.default_params

      start_time = Time.now

      convert_errors_to_action_result(start_time) do
        #
        # Validate the parameters
        #
        self.validate_parameters(eval_environment.params)

        # Run before filters
        controller.before_actions_for(name).each do |action|
          eval_environment.instance_eval(&action.block)
        end

        # Run the actual action
        response = nil
        actions.each do |action|
          response = eval_environment.instance_exec(response, &action)
        end

        # Calculate the length of time this request takes
        time_to_run = Time.now - start_time

        # Prepare a action result
        result = ActionResult.new(self)
        result.data     = response
        result.status   = 'success'
        result.time     = time_to_run.round(2)
        result.flags    = eval_environment.flags
        result.headers  = eval_environment.headers

        # Return the result object
        result
      end
    end

    #
    # Check whether the authenticated user has access to this request.
    # Accepts a Request or an EvalEnvironment.
    #
    # @param request [Moonrope::Request or Moonrope::EvalEnvironment]
    # @return [Boolean]
    #
    def check_access(request = nil)
      if request.is_a?(EvalEnvironment)
        eval_environment = request
      else
        eval_environment = EvalEnvironment.new(@controller.base, request, self)
      end

      if authenticator_to_use.is_a?(Moonrope::Authenticator)
        if rule = authenticator_to_use.rules[access_rule_to_use]
          eval_environment.instance_exec(self, &rule[:block]) == true
        else
          if access_rule_to_use == :default
            # The default rule on any authenticator will allow everything so we
            # don't need to worry about this not being defined.
            true
          else
            # If an access rule that doesn't exist has been requested, we will
            # raise an internal error.
            raise Moonrope::Errors::MissingAccessRule, "The rule '#{access_rule_to_use}' was not found on '#{authenticator_to_use.name}' authenticator"
          end
        end
      else
        true
      end
    end

    #
    # Return whether or not the passed ParamSet is valid for this action
    #
    # @param param_set [Moonrope::ParamSet] the param set to check
    # @return [Boolean]
    #
    def validate_parameters(param_set)
      @params.each do |name, value|
        if value[:required] && param_set[name].nil?
          raise Moonrope::Errors::ParameterError, "`#{name}` parameter is required but is missing"
        end

        if value[:regex] && param_set[name] && !(param_set[name].to_s =~ value[:regex])
          raise Moonrope::Errors::ParameterError, "`#{name}` parameter is invalid"
        end

        if value[:options].is_a?(Array) && param_set[name] && !value[:options].include?(param_set[name])
          raise Moonrope::Errors::ParameterError, "`#{name}` must be one of #{value[:options].join(', ')}"
        end

        if value[:type] && param_set[name]
          if value[:type] == :boolean
            if BOOLEAN_VALUES.include?(param_set[name])
              param_set._set_value(name, TRUE_LIKE_VALUES.include?(param_set[name]))
            else
              raise Moonrope::Errors::ParameterError, "`#{name}` should be a boolean value"
            end
          elsif value[:type].is_a?(Symbol) || value[:type].is_a?(String)
            # Value is a symbol, nothing to do.
          elsif !param_set[name].is_a?(value[:type])
            raise Moonrope::Errors::ParameterError, "`#{name}` should be a `#{value[:type]}` but is a `#{param_set[name].class}`"
          end
        end
      end
      true
    end

    TRUE_LIKE_VALUES = ['true', '1', 1, true]
    FALSE_LIKE_VALUES = ['false', '0', 0, false]
    BOOLEAN_VALUES = TRUE_LIKE_VALUES + FALSE_LIKE_VALUES

    #
    # Does this action allow the user to include/exclude full attributes when
    # calling this action?
    #
    def can_change_full?
      if returns && opts = returns[:structure_opts]
        opts[:paramable] == true ||
        (opts[:paramable].is_a?(Hash) && opts[:paramable].has_key?(:full))
      else
        false
      end
    end

    #
    # Does this action include full attributes by default?
    #
    def includes_full_attributes?
      if returns && opts = returns[:structure_opts]
        (opts[:paramable].is_a?(Hash) && opts[:paramable][:full] == true) ||
        opts[:full] == true
      else
        false
      end
    end

    #
    # Does this action allow the user to include/exclude expansions when calling
    # this action?
    #
    def can_change_expansions?
      if returns && opts = returns[:structure_opts]
        opts[:paramable] == true ||
        (opts[:paramable].is_a?(Hash) && opts[:paramable].has_key?(:expansions))
      else
        false
      end
    end

    #
    # Does this action include full attributes by default?
    #
    def includes_expansion?(expansion)
      if returns && opts = returns[:structure_opts]
        (opts[:paramable].is_a?(Hash) && opts[:paramable][:expansions] == true) ||
        opts[:expansions] == true ||
        (opts[:paramable].is_a?(Hash) && opts[:paramable][:expansions].is_a?(Array) && opts[:paramable][:expansions].include?(expansion)) ||
        (opts[:expansions].is_a?(Array) && opts[:expansions].include?(expansion))
      else
        false
      end
    end

    #
    # Which expansions is the user permitted to include/exclude when calling this
    # action.
    #
    def available_expansions
      if returns && (structure = returns[:structure]) && can_change_expansions?
        if returns[:structure_opts][:paramable].is_a?(Hash) && returns[:structure_opts][:paramable][:expansions].is_a?(Array)
          returns[:structure_opts][:paramable][:expansions]
        else
          @controller.base.structure(structure).all_expansions
        end
      else
        []
      end
    end

  end
end
