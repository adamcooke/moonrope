module Moonrope
  module Rack
    class Middleware
      
      def initialize(base)
        @base = base
      end
      
      def call(env)
        if env['PATH_INFO'] =~ /\A\/#{Moonrope.rack_path_prefix}\/([\w\/\-\.]+)?/
          
          # Create a new request object
          request = @base.request(env, $1 || '')
          
          # Check the request is valid
          unless request.valid?
            return [400, {}, ["Invalid API Request. Must provide a version, controller & action as /#{Moonrope.rack_path_prefix}/v1/controller/action."]]
          end
          
          # Authenticate this request as appropriate
          
          
          [200, {}, ["Hello world!"]]
          
          

        else
          [404, {}, ["Non-API request."]]
        end
      end
      
    end
  end
end
