module Moonrope
  class RackMiddleware
    
    #
    # Initialize a new Moonrope::Rack server
    #
    # @param app [Object] the next Rack application in the stack
    # @param base [Moonrope::Base] the base API to serve
    # @param options [Hash] a hash of options
    # 
    #
    def initialize(app, base, options = {})
      @app = app
      @base = base
      @options = options
    end
    
    #
    # Make a new request
    #
    # @param env [Hash] a rack environment hash
    # @return [Array] a rack triplet
    #
    def call(env)
      if env['PATH_INFO'] =~ Moonrope::Request::PATH_REGEX
        
        if @options[:reload_on_each_request]
          @base.load
        end
        
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
          json = result.to_json
          global_headers = {}
          global_headers['Content-Type'] = 'application/json'
          global_headers['Content-Length'] = json.bytesize.to_s
          [200, global_headers.merge(result.headers), [result.to_json]]
        rescue => e
          [500, {}, ["An internal server occurred."]]
        end

      else
        if @app && @app.respond_to?(:call)
          @app.call(env)
        else
          [404, {}, ["Non-API request"]]
        end
      end
    end
    
  end
end
