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
        eval_environment = EvalEnvironment.new(@controller.core_dsl, :params => params)
        result = ActionResult.new(self)
        result.body = eval_environment.instance_eval(&action)
        result.status = eval_environment.variables[:status] || 200
        result.headers = eval_environment.variables[:headers] || {}
        result
      end
      
      def check_access
        eval_environment = EvalEnvironment.new(@controller.core_dsl)
        if eval_environment.auth
          !!eval_environment.instance_eval(&access)
        else
          false
        end
      end
      
    end
  end
end
