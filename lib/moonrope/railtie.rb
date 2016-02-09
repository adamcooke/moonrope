module Moonrope
  class Railtie < Rails::Railtie

    initializer 'moonrope.initialize' do |app|

      # Initialize a new moonrope base.
      app.config.moonrope = Moonrope::Base.load(Rails.root.join('api'))

      # Set the logger
      Moonrope.logger = Rails.logger

      # Set the environment to match the Rails environment
      app.config.moonrope.environment = Rails.env.to_s

      # Ensure all request use UTC
      app.config.moonrope.on_request = Proc.new do |base, env|
        Time.zone = 'UTC'
      end

      # Set the request regex if one has been set
      if app.config.respond_to?(:moonrope_request_path_regex) && app.config.moonrope_request_path_regex.is_a?(Regexp)
        Moonrope::Request.path_regex = app.config.moonrope_request_path_regex
      end

      if defined?(ActiveRecord)

        # Catch ActiveRecord::RecordNotFound exception as a standard not-found error
        app.config.moonrope.register_external_error ActiveRecord::RecordNotFound do |exception, result|
          result.status = 'not-found'
          result.data = {:message => exception.message}
        end

        # Catch ActiveRecord::DeleteRestrictionError and raise an a DeleteRestrictionError
        app.config.moonrope.register_external_error ActiveRecord::DeleteRestrictionError do |exception, result|
          result.status = 'error'
          result.data = {:code => "DeleteRestrictionError", :message => "Object could not be deleted due to dependency"}
          if exception.message =~ /([\w\-]+)\z/
            result.data[:dependency] = $1
          end
        end

        # Catch ActiveRecord::RecordInvalid and raise an a ValidationError
        app.config.moonrope.register_external_error ActiveRecord::RecordInvalid do |exception, result|
          result.status = 'error'
          errors = exception.record.errors.respond_to?(:to_api_hash) ? exception.record.errors.to_api_hash : exception.record.errors
          result.data = {:code => "ValidationError", :message => "Object could not be saved due to a validation error", :errors => errors}
        end
      end

      # Insert the Moonrope middleware into the application's middleware
      # stack (at the bottom).
      app.middleware.use(
        Moonrope::RackMiddleware,
        app.config.moonrope,
        :reload_on_each_request => !app.config.cache_classes
      )

    end

  end
end
