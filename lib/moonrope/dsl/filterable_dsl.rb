module Moonrope
  module DSL
    class FilterableDSL

      def initialize(action)
        @action = action
      end

      def attribute(name, options = {}, &block)
        @action.filters[name] = options.merge(:name => name, :block => block)
      end
    end
  end
end
