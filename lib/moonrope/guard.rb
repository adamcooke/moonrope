module ::Guard
  class Moonrope < Plugin
    def initialize(options)
      super
      @options = options
      @options[:source] ||= "api"
      @options[:destination] ||= ".apidoc"
    end

    def start
      UI.info "Starting Moonrope Watching"
    end

    def reload
      stop ; start
    end

    def run_all
      generate_moonrope_docs
    end

    def run_on_modifications(paths)
      generate_moonrope_docs
    end

    private

    def generate_moonrope_docs
      if File.exist?(File.join(@options[:destination], 'moonrope.txt'))
        system("rm -Rf #{@options[:destination]}/*")
      end
      system("bundle exec moonrope #{@options[:source]} #{@options[:destination]}")
    end
  end
end
