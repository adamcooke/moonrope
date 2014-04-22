module Moonrope
  module Structures
    class EvalEnvironment
      
      attr_reader :o, :options, :core_dsl
      
      def initialize(core_dsl, object, options = {})
        @core_dsl = core_dsl
        @o = object
        @options = options
      end
      
      #
      # Generate a new structure from the core DSL for the given
      # object and return a hash or nil if the structure doesn't 
      # exist.
      #
      def structure(structure, object, options = {})
        if object && structure = @core_dsl.structure(structure)
          structure.hash(object, options)
        else
          nil
        end
      end
      
    end
  end
end
