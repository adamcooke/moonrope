module Moonrope
  class ActionResult

    #
    # Initialize a new result from a Moonrope::Action.
    #
    # @param action [Moonrope::Action] the action which originated this result
    #
    def initialize(action)
      @action = action
      @headers = {}
      @time = nil
      @flags = {}
    end

    # @return [Object] the return value from the action
    attr_accessor :data

    # @return [String] the status of the request
    attr_accessor :status

    # @return [Hash] headers which have been set in the action
    attr_accessor :headers

    # @return [Float] the length of time to process the action
    attr_accessor :time

    # @return [Hash] flags which have been set in the action
    attr_accessor :flags

    #
    # Return a Hash representation of this ActionResult without the
    # headers.
    #
    #   {
    #     :status => 'success',
    #     :time => 1.32,
    #     :flags => {},
    #     :data => {}
    #   }
    #
    # @return [Hash]
    #
    def to_hash
      {
        :status => self.status,
        :time => self.time,
        :flags => self.flags,
        :data => self.data
      }
    end

    #
    # Return the ActionResult's hash with a JSON.
    #
    # @return [String]
    #
    def to_json
      to_hash.to_json
    end

  end
end
