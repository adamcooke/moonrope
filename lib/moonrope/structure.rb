module Moonrope
  class Structure

    # @return [Symbol] the name of the structure
    attr_accessor :name

    # @return [Proc] the basic data block
    attr_accessor :basic

    # @return [Proc] the full data block
    attr_accessor :full

    # @return [Moonrope::DSL::StructureDSL] the DSL
    attr_reader :dsl

    # @return [Hash] all expansions for the structure
    attr_reader :expansions

    # @return [Moonrope::Base] the base API
    attr_reader :base

    # @return [Hash] attributes which should be included in this structure
    attr_reader :attributes

    #
    # Initialize a new structure
    #
    # @param base [Moonrope::Base]
    # @param name [Symbol]
    # @yield instance evals the contents within the structure DSL
    def initialize(base, name, &block)
      @base = base
      @name = name
      @expansions = {}
      @attributes = {:basic => [], :full => [], :expansion => []}
      @dsl = Moonrope::DSL::StructureDSL.new(self)
      @dsl.instance_eval(&block) if block_given?
    end

    #
    # Return a hash for this struture
    #
    # @param object [Object] the object
    # @param options [Hash] additional options
    # @return [Hash]
    #
    def hash(object, options = {})
      # Set up an environment
      environment = EvalEnvironment.new(base, options[:request], :o => object)

      # Set a new hash
      hash = Hash.new

      # Add the 'basic' structured fields
      DeepMerge.deep_merge! hash_for_attributes(@attributes[:basic], object, environment), hash

      # Always get a basic hash to work from
      if self.basic.is_a?(Proc)
        DeepMerge.deep_merge! environment.instance_eval(&self.basic), hash
      end

      # Enhance with the full hash if requested
      if options[:full]

        # Add the 'full' structured fields
        DeepMerge.deep_merge! hash_for_attributes(@attributes[:full], object, environment), hash

        if self.full.is_a?(Proc)
          full_hash = environment.instance_eval(&self.full)
          DeepMerge.deep_merge! full_hash,hash
        end
      end

      # Add expansions
      if options[:expansions]

        # Add structured expansions
        @attributes[:expansion].each do |attribute|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(attribute.name.to_sym)
          DeepMerge.deep_merge! hash_for_attributes([attribute], object, environment), hash
        end

        # Add the expansions
        expansions.each do |name, expansion|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          DeepMerge.deep_merge!({name.to_sym => environment.instance_eval(&expansion)}, hash)
        end
      end

      # Return the hash
      hash
    end

    private

    #
    # Return a returnable hash for a given set of structured fields.
    #
    def hash_for_attributes(attributes, object, environment)
      return {} unless attributes.is_a?(Array)
      Hash.new.tap do |hash|
        attributes.each do |attribute|

          unless attribute.conditions.empty?
            matched = false
            attribute.conditions.each do |condition|
              if !environment.instance_eval(&condition)
                matched = true
                break
              end
            end
            if matched
              # Skip this item because a condition didn't evaluate
              # to true.
              next
            end
          end

          if attribute.value.is_a?(Proc)
            value = environment.instance_eval(&attribute.value)
          elsif attribute.value
            value = attribute.value
          else
            value = value_for_attribute(object, environment, attribute)
          end

          if attribute.groups.empty?
            hash[attribute.name] = value
          else
            last_hash = hash
            attribute.groups.each_with_index do |group, index|
              last_hash[group] ||= {}
              if index == attribute.groups.size - 1
                last_hash[group][attribute.name] = value
              end
              last_hash = last_hash[group]
            end
          end

        end
      end
    end

    #
    # Return a value for a structured field.
    #
    def value_for_attribute(object, environment,  attribute)
      value = object.send(attribute.source_attribute)
      if value && attribute.structure
        # If a structure is required, lookup the desired structure and set the
        # hash value as appropriate.
        if structure = self.base.structure(attribute.structure)
          structure_opts = attribute.structure_opts || {}
          if value.respond_to?(:map)
            value.map do |v|
              structure.hash(v, structure_opts.merge(:request => environment.request))
            end
          else
            structure.hash(value, structure_opts.merge(:request => environment.request))
          end
        end
      else
        # Return the value as normal for non-structure values.
        value
      end
    end

  end
end
