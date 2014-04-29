module Moonrope
  module DSL
    class StructureRestrictionDSL
      
      #
      # Set or get the data block for the restriction
      #
      # @yield stores the contents of the block as the data
      # @return [Proc]
      #
      def data(&block)
        block_given? ? @data = block : @data
      end

      #
      # Set or get the condition block for the restriction
      #
      # @yield stores the contents of the block as the condition
      # @return [Proc]
      #
      def condition(&block)
        block_given? ? @condition = block : @condition
      end
      
    end
  end
end
