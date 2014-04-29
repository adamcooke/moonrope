module Moonrope
  class Rack
    
    #
    # Initialize a new Moonrope::Rack server
    #
    # @param base [Moonrope::Base] the base API to serve
    #
    def initialize(base)
      @base = base
    end
    
    #
    # Make a new request
    #
    # @param env [Hash] a rack environment hash
    # @return [Array] a rack triplet
    #
    def call(env)
      if env['PATH_INFO'] =~ Moonrope::Request::PATH_REGEX
        
        #
        # Create a new request object
        #
        request = @base.request(env, $1)
        
        #
        # Check the request is valid
        #
        unless request.valid?
          return [400, {}, ["Invalid API Request. Must provide a version, controller & action as /api/v1/controller/action."]]
        end
        
        #
        # Execute the request
        #
        begin
          result = request.execute
          [200, result.headers, [result.to_json]]
        rescue => e
          [500, {}, ["An internal server occurred."]]
        end

      else
        [404, {}, ["Non-API request."]]
      end
    end
    
  end
end
