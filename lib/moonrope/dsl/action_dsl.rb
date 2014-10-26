module Moonrope
  module DSL
    class ActionDSL

      #
      # Initialize a new ActionDSL
      #
      # @param action [Moonrope::Action]
      #
      def initialize(action)
        @action = action
      end

      #
      # Set the description for the action
      #
      #   description "Returns all users which are configured"
      #
      # @param value [String]
      # @return [void]
      #
      def description(value)
        @action.description = value
      end

      #
      # Add a new param to the action's param set.
      #
      #   param :page, "The page number", :default => 2
      #
      # @param name [Symbol] the name of the param
      # @param description [String] a description of the action
      # @param options [Hash] a hash of additional options
      # @return [void]
      #
      def param(name, description, options = {})
        @action.params[name] = options.merge(:description => description)
      end

      #
      # Set the access condition for the action.
      #
      #   access do
      #     auth.is_a?(User)
      #   end
      #
      # @yield the contents of the yield will be saved as the access condition
      # @return [void]
      #
      def access(value = nil, &block)
        @action.access = block_given? ? block : value
      end

      #
      # Set the action to execute when this action is invoked.
      #
      #   action do
      #     # Do something here and return a JSON-able value
      #   end
      #
      # @yield the contents of the yield will be saved as the action
      # @return [void]
      #
      def action(&block)
        @action.action = block
      end

    end
  end
end
