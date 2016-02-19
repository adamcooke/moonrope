module Moonrope
  module DSL
    class FilterableDSL

      def initialize(action)
        @action = action
      end

      def attribute(name, options = {}, &block)
        if options[:type] == Integer || options[:type] == Float
          # Numbers
          options[:operators] ||= [:eq, :not_eq, :gt, :gte, :lt, :lte, :in, :not_in]
        elsif options[:type] == String
          # Strings
          options[:operators] ||= [:eq, :not_eq, :starts_with, :ends_with, :in, :not_in]
        elsif options[:type] == :timestamp
          # Times
          options[:operators] ||= [:eq, :not_eq, :gt, :gte, :lt, :lte]
        else
          # Everything else
          options[:operators] ||= [:eq, :not_eq]
        end
        @action.filters[name] = options.merge(:name => name, :block => block)
      end
    end
  end
end
