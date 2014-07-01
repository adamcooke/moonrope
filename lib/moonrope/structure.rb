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
      @attributes = {}
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
      hash.deep_merge! hash_for_attributes(@attributes.select { |k,v| v[:type] == :basic }, object, environment)
      
      # Always get a basic hash to work from
      if self.basic.is_a?(Proc)
        hash.deep_merge! environment.instance_eval(&self.basic)
      end
      
      # Enhance with the full hash if requested
      if options[:full]
        
        # Add the 'full' structured fields
        hash.deep_merge! hash_for_attributes(@attributes.select { |k,v| v[:type] == :full }, object, environment)
        
        if self.full.is_a?(Proc)
          full_hash = environment.instance_eval(&self.full)
          hash.deep_merge! full_hash
        end
      end
      
      # Add expansions
      if options[:expansions]        
        
        # Add structured expansions
        @attributes.select { |k,v| v[:type] == :expansion }.each do |name, attribute_opts|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          hash.deep_merge!(hash_for_attributes({name => attribute_opts}, object, environment))
        end
        
        # Add the expansions
        expansions.each do |name, expansion|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          hash.deep_merge!(name.to_sym => environment.instance_eval(&expansion))
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
      return {} unless attributes.is_a?(Hash)
      Hash.new.tap do |hash|
        attributes.each do |name, attribute_opts|
          if attribute_opts[:if].is_a?(Proc)
            if !environment.instance_eval(&attribute_opts[:if])
              # Skip this field...
              next
            end
          end
          
          value = value_for_attribute(object, environment, name, attribute_opts)
          if attribute_opts[:group]
            hash[attribute_opts[:group]] ||= {}
            hash[attribute_opts[:group]][name] = value
          else
            hash[name] = value
          end
        end
      end
    end
    
    #
    # Return a value for a structured field.
    #
    def value_for_attribute(object, environment,  name, attribute_opts = {})
      value = object.send(attribute_opts[:name] || name)
      if attribute_opts[:structure]
        # If a structure is required, lookup the desired structure and set the
        # hash value as appropriate.
        if structure = self.base.structure(attribute_opts[:structure] || name)
          structure_opts = attribute_opts[:structure_opts] || {}
          if value.is_a?(Array)
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
