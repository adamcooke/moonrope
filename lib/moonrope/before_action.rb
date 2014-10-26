module Moonrope
  class BeforeAction

    # @return [Array] the names of actions to execute this request on
    attr_accessor :actions

    # @return [Proc] the block to execute in this action
    attr_accessor :block

    # @return [Moonrope::Controller] the associated controller
    attr_reader :controller

    #
    # Initilize a new BeforeAction
    #
    # @param controller [Moonrope::Controller]
    #
    def initialize(controller)
      @controller = controller
      @actions = []
    end

  end
end
