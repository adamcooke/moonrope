module Moonrope
  class BeforeAction
    
    attr_accessor :actions, :block
    attr_reader :controller
    
    def initialize(controller)
      @controller = controller
    end
    
  end
end
