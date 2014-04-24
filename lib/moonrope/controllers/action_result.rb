module Moonrope
  module Controllers
    class ActionResult
      
      def initialize(action)
        @action = action
      end
      
      attr_accessor :body
      attr_accessor :status
      attr_accessor :headers
      
    end
  end
end
