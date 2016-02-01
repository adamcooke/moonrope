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
      FileUtils.cp_r(File.join(@template_root_path, 'assets'), File.join(output_path, 'assets'))
      # Index
      generate_file(output_path, "index.html", "index")
      # Controllers
      @base.controllers.each do |controller|
        generate_file(output_path, File.join("controllers", "#{controller.name}.html"), "controller", {:controller => controller})
        controller.actions.each do |_, action|
          generate_file(output_path, File.join("controllers", controller.name.to_s, "#{action.name}.html"), "action", {:controller => controller, :action => action})
        end
      end
    end

    private

    def generate_file(root_dir, output_file, template_file, variables = {})
      path = File.join(root_dir, output_file)
      globals = {:base => @base, :output_file => output_file, :host => ENV['MR_HOST'], :version => ENV['MR_VERSION'] || "v1", :prefix => ENV['MR_PREFIX'] || "api"}
      file = Erbable.new(variables.merge(globals)).render(File.join(@template_root_path, "#{template_file}.erb"))
      layout = Erbable.new({:body => file}.merge(globals)).render(File.join(@template_root_path, "layout.erb"))
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(layout) }
    end

  end

  class Erbable < OpenStruct

    def asset_path(file)
      path("assets/" + file)
    end

    def full_prefix
      "#{host}/#{prefix}/#{version}"
    end

    def path(file)
      depth = (output_file.split('/').size - 1).times.map { "../" }.join
      depth + file
    end

    def render(template_file)
      ERB.new(File.read(template_file), nil, '-').result(binding)
    end

  end
end
