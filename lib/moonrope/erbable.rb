module Moonrope
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
