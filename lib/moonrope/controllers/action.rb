module Moonrope
  module Controllers
    class Action
      
      attr_reader :controller, :name, :dsl, :params
      attr_accessor :description, :access, :action
      
      def initialize(controller, name)
        @controller = controller
        @name = name
        @dsl = Moonrope::Controllers::ActionDSL.new(self)
        @params = {}
      end
      
      def execute(params = {})
        eval_environment = EvalEnvironment.new(@controller.base, :params => params)
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
          
        rescue Moonrope::Errors::Error => e
          result = ActionResult.new(self)
          result.status = e.status
          result.data = e.data
          result
        end
      end
      
      def check_access
        eval_environment = EvalEnvironment.new(@controller.base)
        if eval_environment.auth
          !!eval_environment.instance_eval(&access)
        else
          false
        end
      end
      
    end
  end
end
