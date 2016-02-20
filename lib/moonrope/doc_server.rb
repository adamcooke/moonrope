require 'moonrope/doc_context'

module Moonrope
  class DocServer

    CONTENT_TYPES = {
      'css' => 'text/css',
      'js' => 'text/javascript',
      'svg' => 'image/svg+xml'
    }

    class << self
      #
      # Set the default path regex which should be matched for requests for
      # API docmentation. By default, this is /api/docs/.
      #
      def path_regex
        @path_regex ||= /\A\/#{Moonrope::Request.path_prefix}docs\/([\w\.]+)\/?([\w\/\-\.]+)?/
      end
      attr_writer :path_regex
    end

    def initialize(app, base, options = {})
      @app = app
      @base = base
      @options = options
    end

    attr_reader :base

    class Generator
      def initialize(base, options = {})
        @base = base
        @options = options
      end

      attr_reader :base

      def template_root_path
        File.expand_path("../../../templates/basic", __FILE__)
      end

      def host
        @options[:host]
      end

      def prefix
        @options[:prefix]
      end

      def version
        @options[:version]
      end

      def generate_file(output_file, template_file, variables = {})
        # Generate the page for the requested template with the given variables
        file = DocContext.new(self, :output_file => output_file, :vars => variables)
        file_string = file.render(File.join(template_root_path, "#{template_file}.erb"))
        # Generate the final page within the layout
        DocContext.new(self, :output_file => output_file, :vars => {:page_title => file.vars[:page_title], :active_nav =>file.vars[:active_nav], :body => file_string}).render(File.join(template_root_path, "layout.erb"))
      end
    end

    def call(env)
      if env['PATH_INFO'] =~ self.class.path_regex
        version = $1
        doc_path = $2
        request = Rack::Request.new(env)
        generator = Generator.new(@base, :host => "#{request.scheme}://#{request.host_with_port}", :version => version, :prefix => env['PATH_INFO'].split('/')[1])

        if @options[:reload_on_each_request]
          @base.load
        end

        file = nil
        content_type = nil

        case doc_path
        when nil, ""
          return [302, {'Location' => "#{env['PATH_INFO']}/welcome"}, ['']]
        when /\Awelcome\z/, /\Aindex\.html\z/
          file = generator.generate_file(doc_path, 'index')
        when /\Acontrollers\/(\w+)(\.html)?\z/
          if controller = @base.controller($1.to_sym)
            file = generator.generate_file(doc_path, 'controller', :controller => controller)
          end
        when /\Acontrollers\/(\w+)\/(\w+)(\.html)?\z/
          if controller = @base.controller($1.to_sym)
            if action = controller.action($2.to_sym)
              file = generator.generate_file(doc_path, 'action', :controller => controller, :action => action)
            end
          end
        when /\Astructures\/(\w+)(\.html)?\z/
          if structure = @base.structure($1.to_sym)
            file = generator.generate_file(doc_path, 'structure', :structure => structure)
          end
        when /\Aauthenticators\/(\w+)(\.html)?\z/
          if authenticator = @base.authenticators[$1.to_sym]
            file = generator.generate_file(doc_path, 'authenticator', :authenticator => authenticator)
          end
        when /\Aassets\/([\w]+)\.([a-z]+)\z/
          path = File.join(generator.template_root_path, 'assets', "#{$1}.#{$2}")
          if File.exist?(path)
            file = File.read(path)
            content_type = CONTENT_TYPES[$2] || 'text/plain'
          end
        end

        if file
          [200, {
            'Content-Type' => content_type || 'text/html',
            'Content-Length' => file.bytesize.to_s},
          [file]]
        else
          [404, {}, ['Not found']]
        end
      else
        return @app.call(env)
      end
    end

  end
end
