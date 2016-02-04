require 'erb'
require 'fileutils'

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
      @base.controllers.select { |c| c.doc != false }.each do |controller|
        generate_file(output_path, File.join("controllers", "#{controller.name}.html"), "controller", {:controller => controller})
        controller.actions.select { |_,a| a.doc != false }.each do |_, action|
          generate_file(output_path, File.join("controllers", controller.name.to_s, "#{action.name}.html"), "action", {:controller => controller, :action => action})
        end
      end
      # Structures
      @base.structures.select { |s| s.doc != false }.each do |structure|
        generate_file(output_path, File.join("structures", "#{structure.name}.html"), "structure", {:structure => structure})
      end
      # Authenticators
      @base.authenticators.values.select { |s| s.doc != false }.each do |authenticator|
        generate_file(output_path, File.join("authenticators", "#{authenticator.name}.html"), "authenticator", {:authenticator => authenticator})
      end

    end

    private

    def generate_file(root_dir, output_file, template_file, variables = {})
      file = Erbable.new(self, output_file, variables)
      file_string = file.render(File.join(@template_root_path, "#{template_file}.erb"))
      layout = Erbable.new(self, output_file, {:page_title => file.vars[:page_title], :active_nav =>file.vars[:active_nav], :body => file_string}).render(File.join(@template_root_path, "layout.erb"))
      path = File.join(root_dir, output_file)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(layout) }
    end

  end

  class Erbable

    attr_reader :vars

    def initialize(generator, output_file, vars = {})
      @generator = generator
      @output_file = output_file
      @vars = vars
    end

    def set_page_title(title)
      @vars[:page_title] = title
    end

    def set_active_nav(nav)
      @vars[:active_nav] = nav
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

    def git_version
      (`git rev-parse HEAD`.strip rescue nil) ||
      ENV["VDT_VERSION"]
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

    def friendly_type(type)
      if type.is_a?(Symbol)
        type.to_s.capitalize
      else
        type.to_s
      end
    end

    def humanize(string)
      string.to_s.gsub(/\_/, ' ')
    end

  end
end
