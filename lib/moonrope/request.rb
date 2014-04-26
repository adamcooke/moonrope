module Moonrope
  class Request
    
    attr_reader :env, :version, :controller_name, :action_name
    
    def initialize(base, env, path)
      @base = base
      @env = env
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
    # Execute the approrpriate action for this requestr
    #
    def execute
      action.execute(self)
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
      rack_request.headers
    end
    
    private
    
    #
    # Return/create a rack request object for use internally
    #
    def rack_request
      @rack_request ||= ::Rack::Request.new(@env)
    end
    
  end
end
