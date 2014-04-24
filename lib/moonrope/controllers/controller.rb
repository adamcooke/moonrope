module Moonrope
  module Controllers
    class Controller
      
      attr_accessor :name, :actions
      attr_reader :core_dsl, :dsl
      
      def initialize(core_dsl, name)
        @core_dsl = core_dsl
        @name = name
        @actions = {}
        @dsl = Moonrope::Controllers::ControllerDSL.new(self)
      end
      
    end
  end
end
