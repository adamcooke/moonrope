module Moonrope
  class Railtie < Rails::Railtie
    
    initializer 'moonrope.initialize' do |app|
      
      # Initialize a new moonrope base from the API defined in
      # $RAILS_ROOT/api directory.
      moonrope_directory = Rails.root.join('api')
      if File.directory?(moonrope_directory)
        app.config.moonrope = Moonrope::Base.load(moonrope_directory)
      else
        $stderr.puts "Moonrope is installed but there is no API directory at ROOT/api."
        next
      end
      
      # Set the logger
      Moonrope.logger = Rails.logger

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

    generators do
      require 'moonrope/rails/generators/install_generator'
      require 'moonrope/rails/generators/structure_generator'
    end
    
  end
end
