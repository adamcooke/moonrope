require 'moonrope/structure'
require 'moonrope/controller'
require 'moonrope/authenticator'

module Moonrope
  module DSL
    class BaseDSL

      #
      # Initiaize a new BaseDSL
      #
      # @param base [Moonrope::Base]
      #
      def initialize(base)
        @base = base
      end

      #
      # Define a new structure
      #
      # @param name [Symbol] the name of the structure
      # @yield instance evals the block within the StructureDSL
      #
      def structure(name, &block)
        if existing = @base.structures.select { |s| s.name == name }.first
          structure = existing
        else
          structure = Moonrope::Structure.new(@base, name)
          @base.structures << structure
        end
        structure.dsl.instance_eval(&block) if block_given?
        structure
      end

      #
      # Define a new controller or append values to an existing
      # controller if it has already been defined.
      #
      # @param name [Symbol] the name of the controller
      # @yield instance evals the block within the ControllerDSL
      #
      def controller(name, &block)
        existing = @base.controllers.select { |a| a.name == name }.first
        if existing
          controller = existing
        else
          controller = Moonrope::Controller.new(@base, name)
          @base.controllers << controller
        end
        controller.dsl.instance_eval(&block) if block_given?
        controller
      end

      #
      # Define a new helper in the global namespace
      #
      # @param name [Symbol] the name of the helper
      # @yield stores the block to execute for the helper
      #
      def helper(name, options = {}, &block)
        if @base.helper(name, nil)
          raise Moonrope::Errors::HelperAlreadyDefined, "Helper has already been defined with name `#{name}`"
        end

        helper_instance = Moonrope::Helper.new(name, nil, options, &block)
        @base.helpers << helper_instance
        helper_instance
      end

      #
      # Define a new authenticator
      #
      def authenticator(name, &block)
        authenticator = Moonrope::Authenticator.new(name)
        dsl = Moonrope::DSL::AuthenticatorDSL.new(authenticator)
        dsl.instance_eval(&block) if block_given?
        @base.authenticators[name] = authenticator
      end

      #
      # Define a new global shared action
      #
      def shared_action(name, &block)
        @base.shared_actions[name] = block
      end

    end
  end
end
