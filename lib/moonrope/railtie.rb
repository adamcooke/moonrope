module Moonrope
  class Railtie < Rails::Railtie
    
    initializer 'moonrope.initialize' do |app|
      
      # Initialize a new moonrope base from the API defined in
      # $RAILS_ROOT/app/api directory.
      moonrope_directory = Rails.root.join('api')
      if File.directory?(moonrope_directory)
        app.config.moonrope = Moonrope::Base.load(moonrope_directory)
      else
        $stderr.puts "Moonrope is installed but there is no API directory at ROOT/api."
        next
      end
      
      # Set the logger
      Moonrope.logger = Rails.logger
      
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
