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

    attr_reader :base

    #
    # Make a new request
    #
    # @param env [Hash] a rack environment hash
    # @return [Array] a rack triplet
    #
    def call(env)
      if env['PATH_INFO'] =~ Moonrope::Request.path_regex
        #
        # Set some global headers which are always returned
        #
        global_headers = {}
        global_headers['Content-Type'] = 'text/plain'
        global_headers['Access-Control-Allow-Origin'] = '*'
        if env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
          global_headers['Access-Control-Allow-Headers'] = env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']
        end
        global_headers['Access-Control-Allow-Methods'] = '*'

        #
        # Options always returns a 200
        #
        if env['REQUEST_METHOD'] == 'OPTIONS'
          return [200, global_headers, ['OK']]
        end

        #
        # Responses are now in JSON
        #
        global_headers['Content-Type'] = 'application/json'

        #
        # Reload if needed
        #
        if @options[:reload_on_each_request]
          base = @base.copy
          begin
            base.load
          rescue => e
            return generate_error_triplet(@base, e, global_headers)
          end
        else
          base = @base
        end

        #
        # Call the on request block if one has been defined for the base.
        #
        if base.on_request.is_a?(Proc)
          base.on_request.call(base, env)
        end

        #
        # Create a new request object
        #
        request = base.request(env, $1)

        #
        # Check the request is valid
        #
        unless request.valid?
          return [400, global_headers, [{:status => 'invalid-controller-or-action'}.to_json]]
        end

        #
        # Execute the request
        #
        begin
          result = request.execute
          json = result.to_json
          Moonrope.logger.info "[#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}] controller=#{request.controller.name} action=#{request.action.name} status=#{result.status} time=#{result.time} ip=#{request.ip} size=#{json.bytesize}"
          global_headers['Content-Length'] = json.bytesize.to_s
          [200, global_headers.merge(result.headers), [json]]
        rescue JSON::ParserError => e
          [400, global_headers, [{:status => 'invalid-json', :details => e.message}.to_json]]
        rescue => e
          generate_error_triplet(base, e, global_headers)
        end

      else
        if @app && @app.respond_to?(:call)
          @app.call(env)
        else
          [404, {}, ["Non-API request"]]
        end
      end
    end

    def generate_error_triplet(base, exception, headers = {})
      Moonrope.logger.info exception.class
      Moonrope.logger.info exception.message
      Moonrope.logger.info exception.backtrace.join("\n")

      response = {:status => 'internal-server-error'}

      # Call any request errors which have been registered on the base
      base.request_error_callbacks.each do |callback|
        callback.call(request, exception)
      end

      # If in development, return more details about the exception which was raised.
      if base.environment == 'development'
        response[:error] = exception.class.to_s
        response[:message] = exception.message
        response[:backtrace] = exception.backtrace[0,6]
      end

      [500, headers, [response.to_json]]
    end

  end
end
