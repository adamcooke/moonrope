module Moonrope
  module EvalHelpers

    #
    # Raise an error.
    #
    # @param type [Symbol] the type of error to raise
    # @param message [String, Hash or Array] options to pass with the error (usually a message)
    #
    def error(type, message)
      case type
      when :not_found           then raise(Moonrope::Errors::NotFound, message)
      when :access_denied       then raise(Moonrope::Errors::AccessDenied, message)
      when :validation_error    then raise(Moonrope::Errors::ValidationError, message)
      when :parameter_error     then raise(Moonrope::Errors::ParameterError, message)
      else
        raise Moonrope::Errors::RequestError, message
      end
    end

    #
    # Return paginated information
    #
    def paginate(collection, max_per_page = 60, &block)
      per_page = params.per_page || 30
      per_page = max_per_page if per_page < 1 || per_page > max_per_page
      paginated_results = collection.page(params.page).per(per_page)
      set_flag :paginated, {:page => params.page, :per_page => per_page, :total_pages => paginated_results.total_pages, :total_records => paginated_results.total_count}
      paginated_results.to_a.map do |result|
        block.call(result)
      end
    end

  end
end
