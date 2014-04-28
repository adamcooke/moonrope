module Moonrope
  module DSL
    class ControllerDSL
    
      def initialize(controller)
        @controller = controller
      end
    
      attr_reader :controller
    
      def action(name, &block)
        action = Moonrope::Action.new(@controller, name)
        action.dsl.instance_eval(&block) if block_given?
        @controller.actions[name] = action
      end
    
      def before(*actions, &block)
        before_action = Moonrope::BeforeAction.new(@controller)
        before_action.block = block
        before_action.actions = actions
        @controller.befores << before_action
      end
    
    end
  end
end
