module Moonrope
  class ActionResult
    
    def initialize(action)
      @action = action
      @headers = {}
      @time = nil
      @flags = {}
    end
    
    attr_accessor :data
    attr_accessor :status
    attr_accessor :headers
    attr_accessor :time
    attr_accessor :flags
    
    def to_hash
      {
        :status => self.status,
        :time => self.time,
        :flags => self.flags,
        :data => self.data
      }
    end
    
    def to_json
      to_hash.to_json
    end
    
  end
end
