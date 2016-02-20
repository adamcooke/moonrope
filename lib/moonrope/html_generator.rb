require 'erb'
require 'fileutils'
require 'moonrope/doc_context'

module Moonrope
  class HtmlGenerator

    def initialize(base, template_root_path)
      @base = base
      @template_root_path = template_root_path
    end

    attr_reader :base
    attr_reader :template_root_path

    def host
      ENV['MR_HOST']
    end

    def prefix
      ENV['MR_PREFIX'] || 'api'
    end

    def version
      ENV['MR_VERSION'] || 'v1'
    end

    def generate(output_path)
      FileUtils.mkdir_p(output_path)
      FileUtils.cp_r(File.join(@template_root_path, 'assets'), File.join(output_path, 'assets'))
      FileUtils.touch(File.join(output_path, 'moonrope.txt'))
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
      file = DocContext.new(self, :html_extensions => true, :welcome_file => 'index', :output_file => output_file, :vars => variables)
      file_string = file.render(File.join(@template_root_path, "#{template_file}.erb"))
      layout = DocContext.new(self, :html_extensions => true, :welcome_file => 'index', :output_file => output_file, :vars => {:page_title => file.vars[:page_title], :active_nav =>file.vars[:active_nav], :body => file_string}).render(File.join(@template_root_path, "layout.erb"))
      path = File.join(root_dir, output_file)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(layout) }
    end

  end

end
