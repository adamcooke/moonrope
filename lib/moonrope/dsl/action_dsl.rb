module Moonrope
  module DSL
    class ActionDSL
    
      def initialize(action)
        @action = action
      end
    
      def description(value)
        @action.description = value
      end
    
      def param(name, description, options = {})
        @action.params[name] = options.merge(:description => description)
      end
    
      def access(value = nil, &block)
        @action.access = block_given? ? block : value
      end
    
      def action(&block)
        @action.action = block
      end
    
    end
  end
end
