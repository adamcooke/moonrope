module Moonrope
  class ParamSet

    #
    # Initialize a new ParamSet
    #
    # @param params [Hash or String] the initial params. If string, will be parsed through JSON.
    #
    def initialize(params = {})
      @params = (params.is_a?(String) ? JSON.parse(params) : params) || {}
      @defaults = {}
    end

    #
    # Return the params as a ruby hash
    #
    def _as_hash
      @defaults.merge(@params).inject({}) do |hash, (k, v)|
        hash[k.to_s] = v
        hash
      end
    end

    #
    # Return the value for the given key
    #
    # @param key [String] the key to lookup
    # @return [Object] the value
    #
    def _value_for(key)
      # Get the value from the params and defaults
      value = @params.has_key?(key.to_s) ? @params[key.to_s] : @defaults[key.to_s]
      # Ensure that empty strings are actually nil.
      value = nil if value.is_a?(String) && value.length == 0
      # Return the value
      value
    end

    alias_method :[], :_value_for
    alias_method :method_missing, :_value_for

    #
    # Set the value for a given param
    #
    # @param key [String]
    # @param value [AnyObject]
    #
    def _set_value(name, value)
      @params[name.to_s] = value
    end

    #
    # Set the defaults for the param set
    #
    # @param defaults [Hash]
    # @return [void]
    def _defaults=(defaults)
      if defaults.is_a?(Hash)
        @defaults = defaults
      end
    end

    #
    # Does the specified key exist?
    #
    # @param key [Symbol or String]
    # @return [Boolean]
    #
    def has?(key)
      @params.keys.include?(key.to_s) || @defaults.keys.include?(key.to_s)
    end

  end
end
