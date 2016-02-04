module Moonrope
  module DSL
    class AuthenticatorDSL

      def initialize(authenticator)
        @authenticator = authenticator
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

      def rule(name, description = nil, &block)
        @authenticator.rules[name] = {:name => name, :description => description, :block => block}
      end

    end
  end
end
