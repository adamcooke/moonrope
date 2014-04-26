module Moonrope
  class Request
    
    PATH_REGEX = /\A\/api\/([\w\/\-\.]+)?/
    
    attr_reader :env, :version, :controller_name, :action_name, :authenticated_user
    
    def initialize(base, env, path = nil)
      @base = base
      @env = env
      if path.nil? && env['PATH_INFO'] =~ PATH_REGEX
        path = $1
      end
      @version, @controller_name, @action_name = path ? path.split("/") : [nil, nil, nil]
    end
    
    #
    # Return the requested API version from the request
    #
    def version
      version = @version.to_s.gsub(/[^0-9]/, '').to_i
      version = 1 if version == 0
      version
    end
    
    #
    # Return whether or not this request is valid and can continue?
    #
    def valid?
      !!(version > 0 && [controller_name, action_name].all? { |c| c =~ /\A[\w\-\.]+\z/} && controller && action)
    end
    
    #
    # Return the controller object for the request
    #
    def controller
      @controller ||= @base.controller(controller_name.to_sym)
    end
    
    #
    # Return the action object for the request
    #
    def action
      @action ||= controller.actions[action_name.to_sym]
    end
    
    #
    # Execute the approrpriate action for this request and return a 
    # ActionResult.
    #
    def execute
      eval_env = EvalEnvironment.new(@base, self)
      if @base.authenticator
        begin
          @authenticated_user = eval_env.instance_eval(&@base.authenticator)
          # If we are authenticated, check whether the action permits access to 
          # this user, if not raise an error.
          if authenticated?
            unless action.check_access(eval_env) == true
              raise Moonrope::Errors::AccessDenied, "Access to #{@path} is not permitted."
            end
          end
        rescue Moonrope::Errors::RequestError => e
          result = Moonrope::Controllers::ActionResult.new(self)
          result.status = e.status
          result.data = e.data
          return result
        end
      end
      action.execute(eval_env)
    end
    
    #
    # Return all user supplier parameters
    #
    def params
      @params ||= Moonrope::ParamSet.new(rack_request.params['params'])
    end
    
    #
    # Return all HTTP headers from the request
    #
    def headers
      @headers ||= self.class.extract_http_request_headers(@env)
    end
    
    #
    # Is this request to the API anonymous?
    #
    def anonymous?
      authenticated_user.nil?
    end
    
    #
    # Is this request to the API authenticated?
    #
    def authenticated?
      !anonymous?
    end
    
    private
    
    #
    # Return/create a rack request object for use internally
    #
    def rack_request
      @rack_request ||= ::Rack::Request.new(@env)
    end
    
    #
    # Extract headers from the rack env
    #
    def self.extract_http_request_headers(env)
      env.reject do |k, v|
        !(/^HTTP_[A-Z_]+$/ === k) || v.nil?
      end.map do |k, v|
        [k.sub(/^HTTP_/, "").gsub("_", "-"), v]
      end.inject(::Rack::Utils::HeaderHash.new) do |hash, k_v|
        k, v = k_v
        hash[k] = v
        hash
      end
    end
    
  end
end
