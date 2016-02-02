require 'erb'

module Moonrope
  class HtmlGenerator

    def initialize(base, template_root_path)
      @base = base
      @template_root_path = template_root_path
    end

    attr_reader :base
    attr_reader :template_root_path

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
      # Structures
      @base.structures.each do |structure|
        generate_file(output_path, File.join("structures", "#{structure.name}.html"), "structure", {:structure => structure})
      end
    end

    private

    def generate_file(root_dir, output_file, template_file, variables = {})
      file = Erbable.new(self, output_file, variables).render(File.join(@template_root_path, "#{template_file}.erb"))
      layout = Erbable.new(self, output_file, {:body => file}).render(File.join(@template_root_path, "layout.erb"))
      path = File.join(root_dir, output_file)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(layout) }
    end

  end

  class Erbable

    def initialize(generator, output_file, vars = {})
      @generator = generator
      @output_file = output_file
      @vars = vars
    end

    def base
      @generator.base
    end

    def host
      ENV["MR_HOST"]
    end

    def prefix
      ENV["MR_PREFIX"] || "api"
    end

    def version
      ENV["MR_VERSION"] || "v1"
    end

    def method_missing(name)
      if @vars.has_key?(name.to_sym)
        @vars[name.to_sym]
      else
        super
      end
    end

    def asset_path(file)
      path("assets/" + file)
    end

    def full_prefix
      "#{host}/#{prefix}/#{version}"
    end

    def path(file)
      depth = (@output_file.split('/').size - 1).times.map { "../" }.join
      depth + file
    end

    def render(template_file)
      ERB.new(File.read(template_file), nil, '-').result(binding)
    end

    def partial(name, attributes = {})
      erb = self.class.new(@generator, @output_file, attributes)
      erb.render(File.join(@generator.template_root_path, "_#{name}.erb"))
    end

  end
end
