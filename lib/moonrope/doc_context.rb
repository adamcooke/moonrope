module Moonrope
  class DocContext

    attr_reader :vars

    def initialize(generator, options = {})
      @generator = generator
      @vars = options.delete(:vars) || {}
      @options = options
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
      @generator.host
    end

    def prefix
      @generator.prefix
    end

    def version
      @generator.version
    end

    def method_missing(name)
      if @vars.has_key?(name.to_sym)
        @vars[name.to_sym]
      else
        super
      end
    end

    def git_version
      ENV["VDT_VERSION"] ||
      (`git rev-parse HEAD`.strip rescue nil)
    end

    def asset_path(file)
      path("assets/" + file)
    end

    def full_prefix
      "#{host}/#{prefix}/#{version}"
    end

    def path(file)
      depth = ((@options[:output_file] || '').split('/').size - 1).times.map { "../" }.join
      if file == :root
        file = depth + (@options[:welcome_file] || "welcome")
      else
        file = depth + file
      end

      if @options[:html_extensions] && !(file =~ /\.[a-z]+\z/)
        file = "#{file}.html"
      end

      file
    end

    def render(template_file)
      ERB.new(File.read(template_file), nil, '-').result(binding)
    end

    def partial(name, attributes = {})
      erb = self.class.new(@generator, @options.merge(:vars => attributes))
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
