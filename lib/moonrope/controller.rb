require 'moonrope/dsl/controller_dsl'

module Moonrope
  class Controller

    attr_accessor :name, :actions, :befores, :friendly_name, :description, :doc, :authenticator, :access_rule, :shared_actions
    attr_reader :base, :dsl

    #
    # Initalize a new Moonrope::Controller
    #
    # @param base [Moonrope::Base] the base
    # @param name [Symbol] the name of the controller
    # @yield instance evals the contents within the ControllerDSL
    #
    def initialize(base, name, &block)
      @base = base
      @name = name
      @actions = {}
      @shared_actions = {}
      @befores = []
      @dsl = Moonrope::DSL::ControllerDSL.new(self)
      @dsl.instance_eval(&block) if block_given?
    end

    #
    # Return an array of before actions which must be executed for
    # the given action.
    #
    # @param action [Symbol] the name of the action to return
    # @return [Array] an array of Moonrope::BeforeAction instances
    #
    def before_actions_for(action)
      @befores.select do |b|
        b.actions.empty? || b.actions.include?(action)
      end
    end

    #
    # Lookup and return an action in this controller by name.
    #
    # @param action [Symbol] the name of the action
    # @return [Moonrope::Action] the action
    #
    def action(action)
      actions[action.to_sym]
    end

    alias_method :/, :action

  end
end
