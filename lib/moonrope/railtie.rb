require 'moonrope/doc_server'

module Moonrope
  class Railtie < Rails::Railtie

    initializer 'moonrope.initialize' do |app|

      # Initialize a new moonrope base.
      Moonrope::Base.instance = Moonrope::Base.load(Rails.root.join('api'))

      # Set the logger
      Moonrope.logger = Rails.logger

      # Set the environment to match the Rails environment
      Moonrope::Base.instance.environment = Rails.env.to_s

      # Ensure all request use UTC
      Moonrope::Base.instance.on_request = Proc.new do |base, env|
        Time.zone = 'UTC'
      end

      # Set the request regex if one has been set
      if app.config.respond_to?(:moonrope_request_path_regex) && app.config.moonrope_request_path_regex.is_a?(Regexp)
        Moonrope::Request.path_regex = app.config.moonrope_request_path_regex
      end

      ActiveSupport.on_load(:active_record) do

        # Catch ActiveRecord::RecordNotFound exception as a standard not-found error
        Moonrope::Base.instance.register_external_error ActiveRecord::RecordNotFound do |exception, result|
          result.status = 'not-found'
          result.data = {:message => exception.message}
        end

        # Catch ActiveRecord::DeleteRestrictionError and raise an a DeleteRestrictionError
        Moonrope::Base.instance.register_external_error ActiveRecord::DeleteRestrictionError do |exception, result|
          result.status = 'error'
          result.data = {:code => "DeleteRestrictionError", :message => "Object could not be deleted due to dependency"}
          if exception.message =~ /([\w\-]+)\z/
            result.data[:dependency] = $1
          end
        end

        # Catch ActiveRecord::RecordInvalid and raise an a ValidationError
        Moonrope::Base.instance.register_external_error ActiveRecord::RecordInvalid do |exception, result|
          result.status = 'error'
          errors = exception.record.errors.respond_to?(:to_api_hash) ? exception.record.errors.to_api_hash : exception.record.errors
          result.data = {:code => "ValidationError", :message => "Object could not be saved due to a validation error", :errors => errors}
        end

      end

      # Insert the documentation middleware
      app.middleware.use(
        Moonrope::DocServer,
        Moonrope::Base.instance,
        :reload_on_each_request => !app.config.cache_classes
      )

      # Insert the Moonrope middleware into the application's middleware
      # stack (at the bottom).
      app.middleware.use(
        Moonrope::RackMiddleware,
        Moonrope::Base.instance,
        :reload_on_each_request => !app.config.cache_classes
      )

    end

  end
end
