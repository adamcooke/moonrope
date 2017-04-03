module Moonrope
  module DSL
    class AuthenticatorDSL

      def initialize(authenticator)
        @authenticator = authenticator
      end

      def friendly_name(value)
        @authenticator.friendly_name = value
      end

      def description(value)
        @authenticator.description = value
      end

      def header(name, description = nil, options = {})
        @authenticator.headers[name] = options.merge(:name => name, :description => description)
      end

      def error(name, description = nil, options = {})
        @authenticator.errors[name] = options.merge(:name => name, :description => description)
      end

      def lookup(&block)
        @authenticator.lookup = block
      end

      def rule(name, error_code, description = nil, &block)
        @authenticator.rules[name] = {:name => name, :error_code => error_code, :description => description, :block => block}
      end

    end
  end
end
