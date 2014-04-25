module Moonrope
  class ParamSet
    
    def initialize(params)
      @params = (params.is_a?(String) ? JSON.parse(params) : params)
    end
    
    def method_missing(name, value = nil)
      if @params.keys.include?(name.to_s)
        @params[name.to_s]
      else
        super
      end
    end
    
    def [](value)
      @params[value.to_s]
    end
    
  end
end
