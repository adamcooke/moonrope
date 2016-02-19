module Moonrope
  module EvalHelpers
    module FilterHelper

      #
      # Return information which has been passed through the filterable filters
      #
      def filter(collection, &block)
        filters_flags = {}
        if params.filters.is_a?(Hash)
          params.filters.each do |key, value|
            options = {}
            if filter = action.filters[key.to_sym]
              if value.is_a?(Hash)
                options[:operator] = value['operator'] ? value['operator'].to_sym : filter[:operators].first
                options[:value] = value['value']
              else
                # If no hash is provided, we'll always attempt to use the first operator
                # for the filter.
                options[:operator] = filter[:operators].first
                options[:value] = value
              end

              # Check that the operator is supported
              unless filter[:operators].include?(options[:operator])
                error 'FilterError', :issue_code => 'InvalidOperator', :issue_message => "The operator '#{options[:operator]}' is not supported for the '#{key}' attribute."
              end

              # Add this item to the flags which will be set at the end of the method
              filters_flags[key] = options

              # Do the filtering...
              if filter[:block]
                # If a block is provided, we'll refer to that to do the lookups
                # and ensure that return the collection
                collection = instance_exec(options[:operator], options[:value], collection, &filter[:block])
              else
                # If no block is provided, we'll fall back to Active Record like where
                # lookups on the original collection.
                case options[:operator]
                when :eq
                  collection = collection.where("#{key} = ?", options[:value].to_s)
                when :not_eq
                  collection = collection.where("#{key} != ?", options[:value].to_s)
                when :starts_with
                  collection = collection.where("#{key} LIKE ?", "#{options[:value].to_s}%")
                when :ends_with
                  collection = collection.where("#{key} LIKE ?", "%#{options[:value].to_s}")
                when :gt
                  collection = collection.where("#{key} > ?", options[:value].to_s)
                when :gte
                  collection = collection.where("#{key} >= ?", options[:value].to_s)
                when :lt
                  collection = collection.where("#{key} < ?", options[:value].to_s)
                when :lte
                  collection = collection.where("#{key} <= ?", options[:value].to_s)
                when :in, :not_in
                  # For checking with arrays, we must make sure the user has sent us
                  # an array otherwise we'll raise an error.
                  unless options[:value].is_a?(Array)
                    error 'FilterError', :issue_code => "ArrayNeeded", :issue_message => "An array value is needed for '#{key}' for in/not_in operator"
                  end
                  values = options[:value].map(&:to_s)
                  collection = options[:operator] == :in ? collection.where(key => values) : collection.where.not(key => values)
                else
                  error 'FilterError', :issue_code => "UnsupportedOperator", :issue_message => "The operator '#{options[:operator]}' is not supported."
                end
              end
            else
              # Raise an error if the attribute has been provided by the consumer
              # that isn't supported by the action.
              error 'FilterError', :issue_code => "UnsupportedAttribute", :issue_message => "The '#{key}' attribute is not supported for filtering on this action."
            end
          end
        end
        set_flag :filters, filters_flags
        instance_exec(collection, &block)
      end

    end
  end
end
