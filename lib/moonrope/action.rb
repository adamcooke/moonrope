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

    # @return [String] the description of the action
    attr_accessor :description

    # @return [Proc] the access check condition for the action
    attr_accessor :access

    # @return [Proc] the action for the action
    attr_accessor :action

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
    # Execute a block of code and catch approprite Moonrope errors and return
    # a result.
    #
    def convert_errors_to_action_result(&block)
      begin
        yield block
      rescue => exception
        case exception
        when Moonrope::Errors::RequestError
          result = ActionResult.new(self)
          result.status = exception.status
          result.data = exception.data
          result
        else
          if error_block = @controller.base.external_errors[exception.class]
            result = ActionResult.new(self)
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
        eval_environment = EvalEnvironment.new(@controller.base, request)
      end

      #
      # Set this actions default parameters in the eval environment so that
      # it has access to them.
      #
      eval_environment.default_params = self.default_params

      #
      # Set the current action to the eval environment so it knows what action
      # invoked this.
      #
      eval_environment.action = self

      convert_errors_to_action_result do
        #
        # Validate the parameters
        #
        self.validate_parameters(eval_environment.params)

        start_time = Time.now

        # Run before filters
        controller.before_actions_for(name).each do |action|
          eval_environment.instance_eval(&action.block)
        end

        # Run the actual action
        response = eval_environment.instance_eval(&action)

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
        eval_environment = EvalEnvironment.new(@controller.base, request)
      end

      access_condition = self.access || @controller.access || @controller.base.default_access

      if eval_environment.auth
        # If there's no authentication object, access is permitted otherwise
        # we'll do the normal testing.
        if access_condition.is_a?(Proc)
          !!eval_environment.instance_exec(self, &access_condition)
        elsif access_condition.is_a?(Symbol)
          !!(eval_environment.auth.respond_to?(access_condition) && eval_environment.auth.send(access_condition))
        elsif access_condition.is_a?(Hash) && access_condition[:must_be] && access_condition[:with]
          !!(eval_environment.auth.is_a?(access_condition[:must_be]) &&
              eval_environment.auth.respond_to?(access_condition[:with]) &&
              eval_environment.auth.send(access_condition[:with])
            )
        elsif access_condition.is_a?(Hash) && access_condition[:must_be]
          !!(eval_environment.auth.is_a?(access_condition[:must_be]))
        elsif access_condition == true
          true
        else
          false
        end
      else
        # No authentication object is available to test with. The result here
        # depends on whether or not an access condition has been defined or not.
        !access_condition
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

        if value[:type] && param_set[name] && !param_set[name].is_a?(value[:type])
          raise Moonrope::Errors::ParameterError, "`#{name}` should be a `#{value[:type]}` but is a `#{param_set[name].class}`"
        end
      end
      true
    end

  end
end
