module Moonrope
  module DSL
    class StructureDSL
      
      # @return [Moonrope::Structure] the associated structure
      attr_reader :structure
      
      #
      # Initialize a new StructureDSL
      #
      # @param structure [Moonrope::Structure]
      #
      def initialize(structure, options = {})
        @structure = structure
        @options = options
      end
      
      def scope(options = {}, &block)
        scope_dsl = self.class.new(@structure, options)
        scope_dsl.instance_eval(&block)
        scope_dsl
      end
      
      def group(name, &block)
        scope(:group => name, &block)
      end
      
      def attribute(type, name, description, options = {})
        attribute                   = StructureAttribute.new(type, name, description)
        attribute.structure         = options[:structure]
        attribute.structure_opts    = options[:structure_opts]
        attribute.value_type        = options[:type]
        attribute.source_attribute  = options[:source] || options[:name]
        attribute.group             = options[:group] || @options[:group]
        attribute.condition         = options[:if] || @options[:if]
        @structure.attributes[type] << attribute
      end
      
      def basic(*args, &block)
        if block_given?
          @structure.basic = block
        else
          attribute(:basic, *args)
        end
      end

      def full(*args, &block)
        if block_given?
          @structure.full = block
        else
          attribute(:full, *args)
        end
      end
      
      def expansion(name, *args, &block)
        if block_given?
          @structure.expansions[name] = block
        else
          attribute(:expansion, name, *args)
        end
      end
    
    end
  end
end
