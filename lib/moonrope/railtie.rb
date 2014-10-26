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

      # Catch ActiveRecord::RecordNotFound exception as a standard not-found error
      if defined?(ActiveRecord)
        app.config.moonrope.register_external_error ActiveRecord::RecordNotFound do |exception, result|
          result.status = 'not-found'
          result.data = {:message => exception.message}
        end

        # Add a helper for auto setting parameters
        app.config.moonrope.dsl.instance_eval do
          helper :auto_set_params_for, :unloadable => false do |object|
            current_action = object.new_record? ? :create_only : :update_only
            request.action.params.select { |k,v| v[:set] == true || v[:set] == current_action }.keys.each do |param|
              object.send("#{param}=", params[param])  if params.has?(param)
            end
          end
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
