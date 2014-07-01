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
    
    # @return [Array] all restrictions for the structure
    attr_reader :restrictions
    
    # @return [Moonrope::Base] the base API
    attr_reader :base
    
    # @return [Hash] fields which should be included in this structure
    attr_reader :fields
    
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
      @restrictions = []
      @fields = {}
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
      hash.merge! hash_for_fieldset(@fields.select { |k,v| v[:type] == :basic }, object, environment)
      
      # Always get a basic hash to work from
      if self.basic.is_a?(Proc)
        hash.merge! environment.instance_eval(&self.basic)
      end
      
      # Enhance with the full hash if requested
      if options[:full]
        
        # Add the 'full' structured fields
        hash.merge! hash_for_fieldset(@fields.select { |k,v| v[:type] == :full }, object, environment)
        
        if self.full.is_a?(Proc)
          full_hash = environment.instance_eval(&self.full)
          hash.merge! full_hash
        end
        
        # Add restrictions
        if environment.auth
          @restrictions.each do |restriction|
            next unless environment.instance_eval(&restriction.condition) == true
            hash.merge! environment.instance_eval(&restriction.data)
          end
        end
      end
      
      # Add expansions
      if options[:expansions]        
        
        # Add structured expansions
        @fields.select { |k,v| v[:type] == :expansion }.each do |name, field_opts|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          hash.merge!(name.to_sym => value_for_field(object, environment, name, field_opts))
        end
        
        # Add the expansions
        expansions.each do |name, expansion|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          hash.merge!(name.to_sym => environment.instance_eval(&expansion))
        end
      end
      
      # Return the hash
      hash
    end
    
    private
    
    #
    # Return a returnable hash for a given set of structured fields.
    #
    def hash_for_fieldset(fields, object, environment)
      return {} unless fields.is_a?(Hash)
      Hash.new.tap do |hash|
        fields.each do |name, field_opts|
          
          if field_opts[:if].is_a?(Proc)
            if !environment.instance_eval(&field_opts[:if])
              # Skip this field...
              next
            end
          end
          
          value = value_for_field(object, environment, name, field_opts)
          if field_opts[:group]
            hash[field_opts[:group]] ||= {}
            hash[field_opts[:group]][name] = value
          else
            hash[name] = value
          end
        end
      end
    end
    
    #
    # Return a value for a structured field.
    #
    def value_for_field(object, environment,  name, field_opts = {})
      value = object.send(field_opts[:name] || name)
      if field_opts[:structure]
        # If a structure is required, lookup the desired structure and set the
        # hash value as appropriate.
        if structure = self.base.structure(field_opts[:structure] || name)
          structure_opts = field_opts[:structure_opts] || {}
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
