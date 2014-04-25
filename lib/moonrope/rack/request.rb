module Moonrope
  module Rack
    class Request
      
      attr_reader :env, :version, :controller_name, :action_name
      
      def initialize(base, env, path)
        @base = base
        @env = env
        @version, @controller_name, @action_name = path.split("/")
      end
      
      def version
        @version.to_s.gsub(/[^0-9]/, '').to_i
      end
      
      def valid?
        !!(version > 0 && [controller_name, action_name].all? { |c| c =~ /\A[\w\-\.]+\z/} && controller && action)
      end
      
      def controller
        @controller ||= @base.controller(controller_name.to_sym)
      end
      
      def action
        @action ||= controller.actions[action_name.to_sym]
      end
      
    end
  end
end
