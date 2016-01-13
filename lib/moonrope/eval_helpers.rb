module Moonrope
  module EvalHelpers

    #
    # Raise an error.
    #
    # @param type [Symbol] the type of error to raise
    # @param message [String, Hash or Array] options to pass with the error (usually a message)
    #
    def error(type, code_or_message, message = nil)
      case type
      when :not_found           then raise(Moonrope::Errors::NotFound, code_or_message)
      when :access_denied       then raise(Moonrope::Errors::AccessDenied, code_or_message)
      when :validation_error    then raise(Moonrope::Errors::ValidationError, code_or_message)
      when :parameter_error     then raise(Moonrope::Errors::ParameterError, code_or_message)
      when :structured_error    then structured_error(code_or_message, message)
      else
        if type.is_a?(String)
          structured_error(type, code_or_message, message.is_a?(Hash) ? message : {})
        else
          raise Moonrope::Errors::RequestError, code_or_message
        end
      end
    end

    #
    # Raises a structured error.
    #
    # @param code [String] the code to return
    # @param message [String] explantory text to return
    # @param additional [Hash] additional data to return with the error
    #
    def structured_error(code, message, additional = {})
      raise Moonrope::Errors::StructuredError, additional.merge(:code => code, :message => message)
    end

    #
    # Return paginated information
    #
    def paginate(collection, max_per_page = 60, &block)
      per_page = params.per_page || 30
      per_page = max_per_page if per_page < 1 || per_page > max_per_page
      paginated_results = collection.page(params.page || 1).per(per_page)
      set_flag :paginated, {:page => params.page || 1, :per_page => per_page, :total_pages => paginated_results.total_pages, :total_records => paginated_results.total_count}
      paginated_results.to_a.map do |result|
        block.call(result)
      end
    end

  end
end
