module Moonrope
  module Controllers
    class Controller
      
      attr_accessor :name, :actions, :befores
      attr_reader :core_dsl, :dsl
      
      def initialize(core_dsl, name)
        @core_dsl = core_dsl
        @name = name
        @actions = {}
        @befores = []
        @dsl = Moonrope::Controllers::ControllerDSL.new(self)
      end
      
      def before_actions_for(action)
        @befores.select do |b|
          b.actions.empty? || b.actions.include?(action)
        end
      end
      
    end
  end
end
