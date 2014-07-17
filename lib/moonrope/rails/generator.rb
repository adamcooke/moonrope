module Moonrope
  class InstallGenerator < Rails::Generators::Base
    desc "This generator creates your a Moonrope directory structure"

    def generate_directories
      empty_directory 'api/controllers'
      empty_directory 'api/helpers'
      empty_directory 'api/structures'
    end

  end
end
