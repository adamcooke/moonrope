module Moonrope
  class InstallGenerator < Rails::Generators::Base
    desc "This generator creates your a Moonrope directory structure"

    def install
      generate_directories
    end

    def generate_directories
      empty_directory 'app/api/controllers'
      empty_directory 'app/api/helpers'
      empty_directory 'app/api/structures'
    end

  end
end
