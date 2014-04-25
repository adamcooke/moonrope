module Moonrope
  module Errors
    
    class Error < StandardError
      attr_reader :options
      
      def initialize(options)
        @options = options
      end
      
      def data
        {:message => @options}
      end
    end
    
    class AccessDenied < Error
      def status
        'access-denied'
      end
    end
    
    class NotFound < Error
      def status
        'not-found'
      end
    end
    
    class ValidationError < Error
      def status
        'validation-error'
      end
      
      def data
        {:errors => @options}
      end
    end
    
    class ParameterError < Error
      def http_status_code
        'parameter-error'
      end
      
      def data
        {:errors => @options}
      end
    end
    
  end
end
