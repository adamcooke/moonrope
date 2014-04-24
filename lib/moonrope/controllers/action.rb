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
      
      def execute(params)
        eval_environment = EvalEnvironment.new(@controller.core_dsl, :params => params)
        eval_environment.instance_eval(&action)
      end
      
      def check_access
        eval_environment = EvalEnvironment.new(@controller.core_dsl)
        !!eval_environment.instance_eval(&access)
      end
      
    end
  end
end
