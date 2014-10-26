module Moonrope
  class Helper

    # @return [Symbol] the name of the helper
    attr_reader :name

    # @return [Moonrope::Controller] the controller this helper belongs to
    attr_reader :controller

    # @return [Proc] the proc to execute
    attr_reader :block

    # @return [Hash] options for this helper
    attr_reader :options

    #
    # Initialize a new helper
    #
    # @param name [Symbol] the name of the helper
    # @param controller [Moonrope::Controller] the controller the helper belongs to
    # @yield stores the block for use later
    #
    def initialize(name, controller, options = {}, &block)
      @name = name
      @controller = controller
      @options = options
      @block = block
    end

  end
end
