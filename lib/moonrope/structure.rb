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
      # Set up an environment for 
      environment = EvalEnvironment.new(base, options[:request], :o => object)

      # Always get a basic hash to work from
      hash = environment.instance_eval(&self.basic)
      
      # Enhance with the full hash if requested
      if options[:full]
        if self.full.is_a?(Proc)
          full_hash = environment.instance_eval(&self.full)
          hash.merge!(full_hash)
        end
        
        # Add restrictions
        if environment.auth
          @restrictions.each do |restriction|
            next unless environment.instance_eval(&restriction.condition) == true
            hash.merge!(environment.instance_eval(&restriction.data))
          end
        end
      end
      
      # Add expansions
      if options[:expansions]
        expansions.each do |name, expansion|
          next if options[:expansions].is_a?(Array) && !options[:expansions].include?(name.to_sym)
          hash.merge!(name => environment.instance_eval(&expansion))
        end
      end
      
      # Return the hash
      hash
    end
    
  end
end
