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

      begin
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
        
      rescue Moonrope::Errors::RequestError => e
        result = ActionResult.new(self)
        result.status = e.status
        result.data = e.data
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
      
      if eval_environment.auth && access.is_a?(Proc)
        !!eval_environment.instance_eval(&access)
      elsif @controller.base.default_access.is_a?(Proc)
        !!eval_environment.instance_exec(self, &@controller.base.default_access)
      else
        false
      end
    end
          
  end
end
