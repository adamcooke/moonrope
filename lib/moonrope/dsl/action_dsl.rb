module Moonrope
  module DSL
    class ActionDSL

      #
      # Initialize a new ActionDSL
      #
      # @param action [Moonrope::Action]
      #
      def initialize(action)
        @action = action
      end

      #
      # Set the title for the action
      #
      #   title "List all users"
      #
      # @param value [String]
      # @return [void]
      #
      def title(value)
        @action.title = value
      end

      #
      # Set the description for the action
      #
      #   description "Returns all users which are configured"
      #
      # @param value [String]
      # @return [void]
      #
      def description(value)
        @action.description = value
      end


      #
      # Set this action so that it isn't documented
      #
      def no_doc!
        @action.doc = false
      end

      #
      # Add a new param to the action's param set.
      #
      #   param :page, "The page number", :default => 2
      #
      # @param name [Symbol] the name of the param
      # @param description_or_options [String/Hash] a description of the action or options
      # @param options_if_description [Hash] a hash of additional options if a description was provided
      # @return [void]
      #
      def param(name, description_or_options = {}, options_if_description = {})
        if description_or_options.is_a?(String)
          options = options_if_description.merge(:description => description_or_options)
        else
          options = description_or_options
        end
        @action.params[name] = options
      end

      #
      # Add a new error to the actions' errors
      #
      #   error "NoUnitFound", "The unit with given {{id}} could not be found"
      #
      # @param name [String] the name of the error
      # @param description [String] a description of the error
      # @return [void]
      #
      def error(name, description, options = {})
        @action.errors[name] = options.merge(:description => description)
      end

      #
      # Sets the type of return value that is expected from a successful call
      # to this API action.
      #
      #   returns :array, :structure => :user
      #
      # @param type [Symbol] the type of object that will be returend
      # @param options [Hash] further options about the returned value
      # @return [void]
      #
      def returns(type, options = {})
        @action.returns = options.merge(:type => type)
      end

      #
      # Set the access condition for the action.
      #
      #   access do
      #     auth.is_a?(User)
      #   end
      #
      # @yield the contents of the yield will be saved as the access condition
      # @return [void]
      #
      def access(value = nil, &block)
        @action.access = block_given? ? block : value
      end

      #
      # Set the action to execute when this action is invoked.
      #
      #   action do
      #     # Do something here and return a JSON-able value
      #   end
      #
      # @yield the contents of the yield will be saved as the action
      # @return [void]
      #
      def action(&block)
        @action.action = block
      end

      #
      # Specify that this action will be returning paginated data. Sets up the
      # parameters for the action as appropriate.
      #
      def paginated(options = {})
        @action.traits << :paginated
        param :page, "The page number", :type => Integer, :required => true, :default => options[:page] || 1
        param :per_page, "The number of items to return per page", :type => Integer, :required => true, :default => options[:per_page] || 30
      end

      #
      # Specify that this action will return data sorted by user provided data.
      #
      def sortable(*fields)
        if fields.empty?
          raise Moonrope::Error, "You must specify at least one field when calling 'sortable'"
        else
          @action.traits << :sortable
          param :sort_by, "The field to sort by", :type => String, :required => true, :default => fields[0].to_s, :options => fields.map(&:to_s)
          param :order, "The direction to order units by", :type => String, :required => true, :default => "asc", :options => ["asc", "desc"]
        end
      end

    end
  end
end
