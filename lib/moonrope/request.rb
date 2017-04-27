module Moonrope
  class Request

    class << self
      attr_accessor :path_regex
      attr_accessor :path_prefix

      # @return [Regex] the regex which should be matched for all API requests
      def path_regex
        @path_regex ||= /\A\/#{path_prefix}([\w\/\-\.]+)?/
      end

      # @return [Regex] the initial path of the prefix to be matched
      def path_prefix
        @path_prefix ||= /api\//
      end
    end

    # @return [Hash] the rack environment
    attr_reader :env
    # @return [String] the name of the controller which was requested
    attr_reader :controller_name
    # @return [String] the name of the action which was requested
    attr_reader :action_name
    # @return [Object] the authenticated user
    attr_reader :identity

    #
    # Initialize a new Moonrope::Request
    #
    # @param base [Moonrope::Base]
    # @param env [Hash] a rack environment has
    # @param path [String] the reqested path (after the /api/ prefix)
    #
    def initialize(base, env, path = nil)
      @base = base
      @env = env
      if path.nil? && env['PATH_INFO'] =~ self.class.path_regex
        path = $1
      end
      @version, @controller_name, @action_name = path ? path.split("/") : [nil, nil, nil]
    end

    #
    # Return the requested API version from the request
    #
    # @return [Integer]
    #
    def version
      version = @version.to_s.gsub(/[^0-9]/, '').to_i
      version = 1 if version == 0
      version
    end

    #
    # Return whether or not this request is valid and can continue?
    #
    # @return [Boolean]
    #
    def valid?
      !!(version > 0 && [controller_name, action_name].all? { |c| c =~ /\A[\w\-\.]+\z/} && controller && action)
    end

    #
    # Return the controller object for the request
    #
    # @return [Moonrope::Controller]
    #
    def controller
      @controller ||= @base.controller(controller_name.to_sym)
    end

    #
    # Return the action object for the request
    #
    # return [Moonrope::Action]
    #
    def action
      @action ||= controller.actions[action_name.to_sym]
    end

    #
    # Execute the appropriate action for the request after running
    # the various authentication checks.
    #
    # @return [Moonrope::ActionResult]
    #
    def execute
      eval_env = EvalEnvironment.new(@base, self, action)

      if action.authenticator_to_use.is_a?(Moonrope::Authenticator)
        result = action.convert_errors_to_action_result do
          if block = action.authenticator_to_use.lookup
            @identity = eval_env.instance_eval(&block)
          end

          unless action.check_access(eval_env) == true
            if rule = action.authenticator_to_use.rules[action.access_rule_to_use]
              eval_env.structured_error(rule[:error_code], rule[:description], :action => action.name, :controller => controller.name)
            else
              eval_env.structured_error("NotPermitted", "You are not permitted to access #{controller.name}/#{action.name}", :action => action.name, :controller => controller.name)
            end
          end
        end

        if result.is_a?(Moonrope::ActionResult)
          return result
        end
      elsif action.authenticator_to_use == :not_found
        raise Moonrope::Errors::MissingAuthenticator, "Wanted to use authenticator that was not defined."
      end

      action.execute(eval_env)
    end

    #
    # Return all user supplier parameters
    #
    # @return [Moonrope::ParamSet]
    #
    def params
      @params ||= begin
        if @env['CONTENT_TYPE'] && @env['CONTENT_TYPE'] =~ /\Aapplication\/json(;|\z)/i
          Moonrope::ParamSet.new(rack_request.body.read)
        else
          Moonrope::ParamSet.new(rack_request.params['params'])
        end
      end
    end

    #
    # Return all HTTP headers from the request
    #
    # @return [Rack::Utils::HeaderHash]
    #
    def headers
      @headers ||= self.class.extract_http_request_headers(@env)
    end

    #
    # Is this request to the API anonymous?
    #
    # @return [Boolean]
    #
    def anonymous?
      identity.nil?
    end

    #
    # Is this request to the API authenticated?
    #
    # @return [Boolean]
    #
    def authenticated?
      !(identity.nil? || identity == false)
    end

    #
    # Return the remote IP
    #
    # @return [String]
    #
    def ip
      rack_request.ip
    end

    private

    #
    # Return/create a rack request object for use internally
    #
    # @return [Rack::Request]
    #
    def rack_request
      @rack_request ||= ::Rack::Request.new(@env)
    end

    #
    # Extract headers from the rack env
    #
    # @return [Rack::Utils::HeaderHash]
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
