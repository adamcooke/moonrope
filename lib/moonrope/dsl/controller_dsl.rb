require 'moonrope/action'
require 'moonrope/before_action'

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
      # Stop this controller frmo being documented
      #
      def no_doc!
        @controller.doc = false
      end

      #
      # Set the friendly name for the controller
      #
      # @param name [String]
      #
      def friendly_name(string)
        @controller.friendly_name = string
      end

      #
      # Set the description for the controller
      #
      # @param description [String]
      #
      def description(description)
        @controller.description = description
      end

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
      # Set the name of the authenticator to use for all actions in this controller
      #
      # @param name [Symbol]
      #
      def authenticator(name)
        @controller.authenticator = name
      end

      #
      # Set the name of the access rule to use for all actions in this controller
      #
      # @param name [Symbol]
      #
      def access_rule(name)
        if name.is_a?(Hash)
          authenticator name.first[0]
          access_rule name.first[1]
        else
          @controller.access_rule = name
        end
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

      #
      # Define a shared action which can be used by any action
      #
      # @param name[Symbol] the name of the shared action
      #
      def shared_action(name, &block)
        @controller.shared_actions[name] = block
      end
    end
  end
end
