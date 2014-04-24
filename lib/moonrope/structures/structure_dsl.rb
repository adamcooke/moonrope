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
      
      #
      # Set up a new restricted data set
      #
      def restricted(&block)
        dsl = RestrictionDSL.new
        dsl.instance_eval(&block)
        structure.restrictions << dsl
      end
      
      #
      # The DSL used for reading the 
      #
      class RestrictionDSL
        def data(&block)
          block_given? ? @data = block : @data
        end
        
        def condition(&block)
          block_given? ? @condition = block : @condition
        end
      end
      
    end
  end
end
