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
      def basic(*args, &block)
        if block_given?
          structure.basic = block
        else
          add(:basic, *args)
        end
        
      end

      #
      # Set the full variables for the structure.
      #
      # @yield stores the contents of the block for the full data
      # @return [void]
      #
      def full(*args, &block)
        if block_given?
          structure.full = block
        else
          add(:full, *args)
        end
      end
    
      #
      # Add a new expansion.
      #
      # @param name [Symbol] the name of the expansion
      # @yield sets the block to execute for the expansion if requested
      # @return [void]
      #
      def expansion(name, *args, &block)
        if block_given?
          structure.expansions[name] = block
        else
          add(:expansion, name, *args)
        end
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
      
      #
      # Add a new field to this structure
      #
      # @param type [Symbol] the type of field
      # @param name [Symbol] the name of the field
      # @param description [String] a description of the field
      # @param options [Hash] options
      # @return void
      #
      def add(type, name, description, options = {})
        @structure.fields[name] = options.merge(:type => type, :description => description)
      end
    
    end
  end
end
