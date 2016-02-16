module Moonrope
  module Errors

    class Error < StandardError
    end

    class HelperAlreadyDefined < Error; end
    class MissingAuthenticator < Error; end
    class MissingAccessRule < Error; end
    class InvalidSharedAction < Error; end

    class RequestError < Error
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def status
        @options.is_a?(Hash) ? @options[:status] || 'error'  : 'error'
      end

      def data
        {:message => @options}
      end
    end

    class StructuredError < RequestError
      def status
        "error"
      end

      def data
        @options
      end
    end

    class AccessDenied < RequestError
      def status
        'access-denied'
      end
    end

    class NotFound < RequestError
      def status
        'not-found'
      end
    end

    class ValidationError < RequestError
      def status
        'validation-error'
      end

      def data
        {:errors => @options}
      end
    end

    class ParameterError < RequestError
      def status
        'parameter-error'
      end
    end

  end
end
