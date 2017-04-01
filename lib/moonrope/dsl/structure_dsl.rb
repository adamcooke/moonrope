require 'moonrope/structure_attribute'

module Moonrope
  module DSL
    class StructureDSL

      # @return [Moonrope::Structure] the associated structure
      attr_reader :structure

      # @return [Array] groups which should applied
      attr_accessor :groups

      # @return [Array] conditions which should applied
      attr_accessor :conditions

      # @return [Hash] options
      attr_accessor :options

      #
      # Initialize a new StructureDSL
      #
      # @param structure [Moonrope::Structure]
      #
      def initialize(structure)
        @structure = structure
        @options = {}
        @groups = []
        @conditions = []
      end

      def no_doc!
        @structure.doc = false
      end

      def scope(options = {}, &block)
        scope_dsl = self.class.new(@structure)
        scope_dsl.options = options
        scope_dsl.instance_eval(&block)
      end

      def group(name, &block)
        scope_dsl = self.class.new(@structure)
        scope_dsl.groups = [@groups, name].flatten
        scope_dsl.conditions = @conditions
        scope_dsl.instance_eval(&block)
      end

      def condition(condition, description = nil, &block)
        scope_dsl = self.class.new(@structure)
        if condition.is_a?(Hash) && condition.size == 1
          condition = {:authenticator => condition.first[0], :access_rule => condition.first[1]}
        elsif condition.is_a?(Symbol)
          condition = {:authenticator => :default, :access_rule => condition}
        else
          condition = {:block => condition, :description => description}
        end
        scope_dsl.conditions = [@conditions, condition].flatten
        scope_dsl.groups = @groups
        scope_dsl.instance_eval(&block)
      end

      def attribute(type, name, options_or_description = {}, options_if_description = {})

        if options_or_description.is_a?(String)
          options_if_description[:description] = options_or_description
          options = options_if_description
        else
          options = options_or_description
        end

        attribute                   = StructureAttribute.new(type, name)
        attribute.description       = options[:description]
        attribute.structure         = options[:structure]
        attribute.structure_opts    = options[:structure_opts]
        attribute.value_type        = options[:type]
        attribute.source_attribute  = options[:source_attribute]
        attribute.value             = options[:value]
        attribute.example           = options[:eg] || options[:example]
        attribute.doc               = options[:doc]
        attribute.mutation          = options[:mutation]
        attribute.groups            = @groups
        attribute.conditions        = @conditions
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
          if args[0].is_a?(String)
            attrs = args[1] || {}
            attrs[:description] = args[0]
          elsif args[0].is_a?(Hash)
            attrs = atrs[0]
          else
            attrs = {}
          end

          @structure.expansions[name] = attrs.merge({:block => block, :conditions => @conditions})
        else
          attribute(:expansion, name, *args)
        end
      end

    end
  end
end
