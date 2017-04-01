require 'moonrope/dsl/structure_dsl'

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

    # @return [Bool] should this structure be documented
    attr_accessor :doc

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
    # Return details for the given attribute
    #
    def attribute(name)
      @attributes[:basic].select { |p| p.name == name }.first ||
      @attributes[:full].select { |p| p.name == name }.first ||
      @attributes[:expansion].select { |p| p.name == name }.first
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
      environment = EvalEnvironment.new(base, options[:request], options[:request] ? options[:request].action : nil, :o => object)

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

      if options[:attributes]
        hash.reject! { |k,v| !options[:attributes].include?(k.to_sym) }
      end

      # Add expansions
      if options[:expansions]

        if options[:expansions].is_a?(Array)
          expansions_to_include = options[:expansions].each_with_object({}) do |expan, hash|
            if expan.is_a?(Symbol) || expan.is_a?(String)
              hash[expan.to_sym] = {}
            elsif expan.is_a?(Hash)
              hash[expan.first.first.to_sym] = expan.first.last
            end
          end
        else
          expansions_to_include = true
        end

        # Add structured expansions
        @attributes[:expansion].each do |attribute|
          next if expansions_to_include.is_a?(Hash) && !expansions_to_include.keys.include?(attribute.name.to_sym)
          DeepMerge.deep_merge! hash_for_attributes([attribute], object, environment, :structure_opts => expansions_to_include.is_a?(Hash) && expansions_to_include[attribute.name.to_sym]), hash
        end

        # Add the expansions
        expansions.each do |name, expansion|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          next unless check_conditions(environment, expansion[:conditions])
          DeepMerge.deep_merge!({name.to_sym => environment.instance_eval(&expansion[:block])}, hash)
        end
      end

      # Return the hash
      hash
    end

    #
    # Return an array of all expansions which are available on this structure
    #
    def all_expansions
      @attributes[:expansion].map(&:name) + expansions.keys
    end

    #
    # Return the description for a given condition hash
    #
    def description_for_condition(condition)
      if condition[:authenticator] && condition[:access_rule]
        if authenticator = base.authenticators[condition[:authenticator]]
          if access_rule = authenticator.rules[condition[:access_rule]]
            access_rule[:description]
          end
        end
      else
        condition[:description]
      end
    end

    private

    #
    # Call all conditions provided and return whether they pass or not
    #
    def check_conditions(environment, conditions)
      conditions.each do |condition|
        if condition[:block]
          unless environment.instance_eval(&condition[:block])
            return false
          end
        elsif condition[:authenticator] && condition[:access_rule]
          if authenticator = base.authenticators[condition[:authenticator]]
            if access_rule = authenticator.rules[condition[:access_rule]]
              # If we have an authenticator and access rule, use the access rule
              # block with this environment to determine if we should include the
              # given block or not.
              unless environment.instance_exec(self, &access_rule[:block])
                return false
              end
            else
              raise Moonrope::Errors::MissingAccessRule, "The rule '#{condition[:access_rule]}' was not found on '#{authenticator.name}' authenticator"
            end
          else
            raise Moonrope::Errors::MissingAuthenticator, "The authentication '#{condition[:authenticator]}' was not found"
          end
        end
      end
      true
    end

    #
    # Return a returnable hash for a given set of structured fields.
    #
    def hash_for_attributes(attributes, object, environment, value_options = {})
      return {} unless attributes.is_a?(Array)
      Hash.new.tap do |hash|
        attributes.each do |attribute|

          unless attribute.conditions.empty?
            unless check_conditions(environment, attribute.conditions)
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
            value = value_for_attribute(object, environment, attribute, value_options)
          end

          value = attribute.mutate(value)

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
    def value_for_attribute(object, environment, attribute, options = {})
      if attribute.source_attribute.is_a?(Proc)
        value = environment.instance_eval(&attribute.source_attribute)
      else
        value = object.send(attribute.source_attribute)
      end

      if value && attribute.structure
        # If a structure is required, lookup the desired structure and set the
        # hash value as appropriate.
        if structure = self.base.structure(attribute.structure)
          structure_opts = options[:structure_opts] || attribute.structure_opts || {}
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
