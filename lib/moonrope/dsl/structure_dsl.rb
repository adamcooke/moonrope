module Moonrope
  module DSL
    class StructureDSL
      
      #
      # Initialize a new StructureDSL
      #
      # @param structure [Moonrope::Structure]
      #
      def initialize(structure)
        @structure = structure
      end
      
      # @return [Moonrope::Structure] the associated structure
      attr_reader :structure
    
      #
      # Set the basic variables for the structure.
      #
      # @yield stores the contents of the block for the basic data
      # @return [void]
      #
      def basic(&block)
        structure.basic = block
      end

      #
      # Set the full variables for the structure.
      #
      # @yield stores the contents of the block for the full data
      # @return [void]
      #
      def full(&block)
        structure.full = block
      end
    
      #
      # Add a new expansion.
      #
      # @param name [Symbol] the name of the expansion
      # @yield sets the block to execute for the expansion if requested
      # @return [void]
      #
      def expansion(name, &block)
        structure.expansions[name] = block
      end
    
      #
      # Add a new restricted block.
      #
      # @yield instance evals the block within RestrictionDSL
      # @return [Moonrope::DSL::RestrictionDSL]
      #
      def restricted(&block)
        dsl = Moonrope::DSL::StructureRestrictionDSL.new
        dsl.instance_eval(&block)
        structure.restrictions << dsl
        dsl
      end
    
    end
  end
end
