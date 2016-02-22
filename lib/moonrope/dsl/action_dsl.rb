require 'moonrope/errors'
require 'moonrope/dsl/filterable_dsl'

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
      def param(name, description_or_options = {}, options_if_description = {}, &block)
        if description_or_options.is_a?(String)
          options = options_if_description.merge(:description => description_or_options)
        else
          options = description_or_options
        end

        options[:from_structure] ||= @from_structure if @from_structure

        if structure = options[:from_structure]
          if @action.controller && structure = @action.controller.base.structure(structure)
            if attribute = structure.attribute(name)
              options[:description] ||= attribute.description
              options[:type] ||= attribute.value_type
            end
          end
        end

        options[:apply] = block if block_given?
        options[:from_shared_action] = @within_shared_action.dup if @within_shared_action
        @action.params[name] = options
      end

      #
      # Specifies that all params within this block should be marked as being from
      # a given structure
      #
      #    from_structure :user do
      #      param :username
      #    end
      #
      # @param name [Symbol] the name of the structure
      #
      def from_structure(name, &block)
        @from_structure = name
        self.instance_eval(&block)
      ensure
        @from_structure = nil
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
        @action.errors[name] = options.merge(:description => description, :from_share => @within_share)
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
      # Sets the name of the authenticator to use for this action
      #
      # @param name [Symbol] the name of the authenticator
      #
      def authenticator(name)
        @action.authenticator = name
      end

      #
      # Sets the name of the access rule to use for this action
      #
      # @param name [Symbol] the name of the authenticator
      #
      def access_rule(name)
        if name.is_a?(Hash)
          authenticator name.first[0]
          access_rule name.first[1]
        else
          @action.access_rule = name
        end
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
        @action.actions << block
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
          raise Moonrope::Errors::Error, "You must specify at least one field when calling 'sortable'"
        else
          if fields.first.is_a?(Hash)
            default_order = fields.first.first[1].to_s
            fields[0] = fields.first.first[0]
          else
            default_order = 'asc'
          end
          @action.traits << :sortable
          param :sort_by, "The field to sort by", :type => String, :required => true, :default => fields[0].to_s, :options => fields.map(&:to_s)
          param :order, "The direction to order units by", :type => String, :required => true, :default => default_order, :options => ["asc", "desc"]
        end
      end

      #
      # Specify that this action will return data which can be filtered by specifying
      # certain parameters on a filter parameter
      #
      def filterable(&block)
        if @action.errors['FilterError'].nil?
          error 'FilterError', "An error has occurred while processing filters for this action", :attributes => {:issue_code => "A more specific issue code", :issue_message => "A more specific message about the issue"}
        end

        if @action.params[:filters].nil?
          param :filters, "A hash of filters to apply to results", :type => Hash, :default => {}
        end
        dsl = FilterableDSL.new(@action)
        dsl.instance_eval(&block)
      end

      #
      # Include any block from the controller shares
      #
      def use(name, options = {})
        if block = (@action.controller.shared_actions[name] || @action.controller.base.shared_actions[name])
          @within_shared_action ||= []
          @within_shared_action << name
          self.instance_exec(options, &block)
        else
          raise Moonrope::Errors::InvalidSharedAction, "Invalid share name #{name}"
        end
      ensure
        @within_shared_action.delete(name) if @within_shared_action
      end

    end
  end
end
