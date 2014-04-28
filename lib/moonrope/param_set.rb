module Moonrope
  class ParamSet
    
    def initialize(params = {})
      @params = (params.is_a?(String) ? JSON.parse(params) : params) || {}
      @defaults = {}
    end
    
    def method_missing(name, value = nil)
      _value_for(name.to_s) || nil
    end
    
    def [](key)
      _value_for(key) || nil
    end
    
    def _value_for(key)
      # Get the value from the params and defaults
      value = (@params[key.to_s] || @defaults[key.to_s])
      # Ensure that empty strings are actually nil.
      value = nil if value.is_a?(String) && value.length == 0
      # Return the value
      value
    end
    
    def _defaults=(defaults)
      if defaults.is_a?(Hash)
        @defaults = defaults
      end
    end
    
  end
end
