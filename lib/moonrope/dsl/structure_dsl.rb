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
          attribute(:basic, *args)
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
          attribute(:full, *args)
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
          attribute(:expansion, name, *args)
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
      # Add a new attribute to this structure
      #
      # @param type [Symbol] the type of attribute
      # @param name [Symbol] the name of the attribute
      # @param description [String] a description of the attribute
      # @param options [Hash] options
      # @return void
      #
      def attribute(type, name, description, options = {})
        @structure.attributes[name] = options.merge(:type => type, :description => description)
      end
      
      #
      # All attributes within this group will be added to a hash named 
      # the same
      #
      def group(name, &block)
        group_dsl = GroupDSL.new(self, name)
        group_dsl.instance_eval(&block)
        group_dsl
      end
    
      #
      # A DSL class for groups
      #
      class GroupDSL
        def initialize(dsl, group_name)
          @dsl = dsl
          @group_name = group_name
        end
        
        def attribute(name, description, options = {})
          @dsl.attribute(:full, name, description, options.merge(:group => @group_name))
        end
        
        alias_method :full, :attribute
      end
      
    end
  end
end
