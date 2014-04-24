module Moonrope
  module Structures
    class EvalEnvironment
      
      attr_reader :o, :core_dsl
      
      def initialize(core_dsl, object)
        @core_dsl = core_dsl
        @o = object
      end
      
      #
      # Return the version of the API which has been requested
      #
      def version
        Moonrope.globals[:version] || 1
      end
      
      #
      # Return the authenticated user
      #
      def auth
        Moonrope.globals[:auth]
      end
      
      #
      # Return the globals
      #
      def globals
        Moonrope.globals
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
