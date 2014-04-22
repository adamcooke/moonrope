module Moonrope
  module Structures
    class StructureDSL
      
      def initialize(structure)
        @structure = structure
      end
      
      attr_reader :structure
      
      #
      # Set or get a basic data block for this structure
      #
      def basic(&block)
        structure.basic = block
      end

      #
      # Set or get a full data block for the structure
      #
      def full(&block)
        structure.full = block
      end
      
      #
      # Set up a new expansion
      #
      def expansion(name, &block)
        structure.expansions[name] = block
      end
      
    end
  end
end
