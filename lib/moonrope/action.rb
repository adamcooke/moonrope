module Moonrope
  class Action
    
    attr_reader :controller, :name, :dsl, :params
    attr_accessor :description, :access, :action
    
    def initialize(controller, name)
      @controller = controller
      @name = name
      @dsl = Moonrope::DSL::ActionDSL.new(self)
      @params = {}
    end
    
    #
    # Executes the action and returns a ActionResult object with the result
    # of the action. Accepts a Request or an EvalEnvironment.
    #
    def execute(request = nil)
      if request.is_a?(EvalEnvironment)
        eval_environment = request
      else
        eval_environment = EvalEnvironment.new(@controller.base, request)
      end
      
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
        result.flags    = eval_environment.variables[:flags]    || {}
        result.headers  = eval_environment.variables[:headers]  || {}
        
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
    def check_access(request = nil)
      if request.is_a?(EvalEnvironment)
        eval_environment = request
      else
        eval_environment = EvalEnvironment.new(@controller.base, request)
      end
      
      if eval_environment.auth
        !!eval_environment.instance_eval(&access)
      else
        false
      end
    end
          
  end
end