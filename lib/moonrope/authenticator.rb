require 'moonrope/dsl/authenticator_dsl'

module Moonrope
  class Authenticator

    def initialize(name, &block)
      @name = name
      @headers = {}
      @errors = {}
      @rules = {}
      if block_given?
        dsl = Moonrope::DSL::AuthenticatorDSL.new(self)
        dsl.instance_eval(&block)
      end
    end

    # @return [Symbol] the name of the authenticator
    attr_reader :name

    # @return [String] the friendly name for the authenticator
    attr_accessor :friendly_name

    # @return [String] the description for the authenticator
    attr_accessor :description

    # @return [Proc] the lookup block
    attr_accessor :lookup

    # @return [Hash] the headers that this authenticator uses
    attr_reader :headers

    # @return [Hash] the errors this authenticator can raise
    attr_reader :errors

    # @return [Hash] the rules this authenticator provides
    attr_reader :rules

    # @return [Bool] whether or not the action should be documented
    attr_accessor :doc

  end
end
