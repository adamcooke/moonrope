require 'erb'

module Moonrope
  class HtmlGenerator

    def initialize(base, template_root_path)
      @base = base
      @template_root_path = template_root_path
    end

    def generate(output_path)
      FileUtils.rm_r(output_path) if File.directory?(output_path)
      FileUtils.mkdir_p(output_path)
      # Index
      generate_file(File.join(output_path, "index.html"), "index")
      # Controllers
      @base.controllers.each do |controller|
        FileUtils.mkdir_p(File.join(output_path, "controllers"))
        generate_file(File.join(output_path, "controllers", "#{controller.name}.html"), "controller", {:controller => controller})
        controller.actions.each do |_, action|
          FileUtils.mkdir_p(File.join(output_path, "controllers", controller.name.to_s))
          generate_file(File.join(output_path, "controllers", controller.name.to_s, "#{action.name}.html"), "action", {:controller => controller, :action => action})
        end
      end
    end

    private

    def generate_file(path, template_file, variables = {})
      file = Erbable.new(variables.merge(:base => @base)).render(File.join(@template_root_path, "#{template_file}.erb"))
      layout = Erbable.new(:base => @base, :body => file).render(File.join(@template_root_path, "layout.erb"))
      File.open(path, 'w') { |f| f.write(layout) }
    end

  end

  class Erbable < OpenStruct

    def hello_world
      "<p>hello world</p>"
    end

    def render(template_file)
      ERB.new(File.read(template_file), nil, '-').result(binding)
    end
  end
end
