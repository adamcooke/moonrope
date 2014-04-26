module Moonrope
  module Structures
    class Structure
      
      attr_accessor :name, :basic, :full
      attr_reader :dsl, :expansions, :restrictions, :base
      
      def initialize(base, name)
        @base = base
        @name = name
        @expansions = {}
        @restrictions = []
        @dsl = Moonrope::Structures::StructureDSL.new(self)
      end
      
      #
      # Return a hash for this struture
      #
      def hash(object, options = {})
        # Set up an environment for 
        environment = EvalEnvironment.new(base, options[:request], :o => object)

        # Always get a basic hash to work from
        hash = environment.instance_eval(&self.basic)
        
        # Enhance with the full hash if requested
        if options[:full]
          full_hash = environment.instance_eval(&self.full)
          hash.merge!(full_hash)
          
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
end
