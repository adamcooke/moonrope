module Moonrope
  module DSL
    class ControllerParamSetDSL

      def initialize(params_hash)
        @params_hash = params_hash
      end

      #
      # Add a new param to the param set.
      #
      #   param :page, "The page number", :default => 2
      #
      # @param name [Symbol] the name of the param
      # @param description_or_options [String/Hash] a description of the action or options
      # @param options_if_description [Hash] a hash of additional options if a description was provided
      # @return [void]
      #
      def param(name, description_or_options = {}, options_if_description = {}, &block)
        if description_or_options.is_a?(String)
          options = options_if_description.merge(:description => description_or_options)
        else
          options = description_or_options
        end
        options[:apply] = block
        @params_hash[name] = options
      end

    end
  end
end
