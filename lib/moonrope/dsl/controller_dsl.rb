module Moonrope
  module DSL
    class ControllerDSL

      #
      # Initialize a new ControllerDSL
      #
      # @param controller [Moonrope::Controller]
      #
      def initialize(controller)
        @controller = controller
      end

      # @return [Moonrope::Controller] the associated controller
      attr_reader :controller

      #
      # Defines a new action within the controller.
      #
      # @param name [Symbol]
      # @yield instance evals the block within the ActionDSL
      # @return [Moonrope::Action] the new action instance
      #
      def action(name, &block)
        action = Moonrope::Action.new(@controller, name)
        action.dsl.instance_eval(&block) if block_given?
        @controller.actions[name] = action
        action
      end

      #
      # Defines a new before action within the controller.
      #
      # @param actions [Symbol] the names of the actions to apply to (none for all)
      # @yield stores the block as the block to be executed
      # @return [Moonrope::BeforeAction]
      #
      def before(*actions, &block)
        before_action = Moonrope::BeforeAction.new(@controller)
        before_action.block = block
        before_action.actions = actions
        @controller.befores << before_action
        before_action
      end

      #
      # Defines the access required for controller methods which do not
      # define their own access.
      #
      def access(value = nil, &block)
        @controller.access = block_given? ? block : value
      end

      #
      # Defines a new helper for this controller.
      #
      # @param name [Symbol] the name of the helper
      # @yield stores the block to execute for the helper
      #
      def helper(name, options = {}, &block)
        if @controller.base.helper(name, @controller)
          raise Moonrope::Errors::HelperAlreadyDefined, "Helper has already been defined with name `#{name}`"
        end

        @controller.base.helpers << Moonrope::Helper.new(name, @controller, options, &block)
      end
    end
  end
end
