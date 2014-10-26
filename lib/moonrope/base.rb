module Moonrope
  class Base

    #
    # Load a set of Moonrope configuration files from a given
    # directory.
    #
    # @param path [String] the path to a directory containing Moonrope files
    # @return [Moonrope::Base]
    #
    def self.load(path)
      api = self.new
      api.load(path)
      api
    end

    # @return [Array] the array of defined structures
    attr_reader :structures

    # @return [Array] the array of defined controllers
    attr_accessor :controllers

    # @return [Array] the array of defined helpers
    attr_accessor :helpers

    # @return [Moonrope::DSL::BaseDSL] the base DSL
    attr_accessor :dsl

    # @return [Proc] the authentictor
    attr_accessor :authenticator

    # @return [Proc] the default access condition
    attr_accessor :default_access

    # @return [Array] the array of directories to load from  (if relevant)
    attr_accessor :load_directories

    # @return [String] the moonrope environment
    attr_accessor :environment

    # @return [Proc] a proc to execute before every request
    attr_accessor :on_request

    #
    # Initialize a new instance of the Moonrope::Base
    #
    # @yield instance evals the contents within the Base DSL
    #
    def initialize(&block)
      unload
      @environment = 'development'
      @load_directories = []
      @dsl = Moonrope::DSL::BaseDSL.new(self)
      @dsl.instance_eval(&block) if block_given?
    end

    #
    # Reset the whole base to contain no data.
    #
    def unload
      @structures = []
      @controllers = []
      @helpers = @helpers.is_a?(Array) ? @helpers.select { |h| h.options[:unloadable] == false } : []
      @authenticator = nil
      @default_access = nil
    end

    #
    # Reload this whole base API from the path
    #
    def load(*directories)
      directories = self.load_directories if directories.empty?
      if directories.size > 0
        unload
        new_directories = []
        directories.each do |directory|
          if load_directory(directory)
            new_directories << directory
          end
        end
        self.load_directories = new_directories
        self
      else
        raise Moonrope::Errors::Error, "Can't reload Moonrope::Base as it wasn't required from a directory"
      end
    end

    alias_method :reload, :load

    #
    # Load from a given directory
    #
    def load_directory(directory)
      if File.exist?(directory)
        Dir["#{directory}/**/*.rb"].each do |filename|
          self.dsl.instance_eval(File.read(filename), filename)
        end
        true
      else
        false
      end
    end

    #
    # Add a dirctory to the directories to load
    #
    def add_load_directory(directory)
      if load_directory(directory)
        self.load_directories << directory unless self.load_directories.include?(directory)
        true
      else
        false
      end
    end

    #
    # Return a structure of the given name
    #
    # @param name [Symbol] the name of the structure
    # @return [Moonrope::Structure]
    #
    def structure(name)
      structures.select { |s| s.name == name }.first
    end

    alias_method :[], :structure

    #
    # Return a controller of the given name
    #
    # @param name [Symbol] the name of the controller
    # @return [Moonrope::Controller]
    #
    def controller(name)
      controllers.select { |a| a.name == name }.first
    end

    alias_method :/, :controller

    #
    # Create a new rack request for this API.
    #
    # @return [Moonrope::Request] a new request object
    #
    def request(*args)
      Moonrope::Request.new(self, *args)
    end

    #
    # Return a helper for the given name and, potentially controller
    #
    # @param name [Symbol] the name of the helper
    # @param controller [Moonrope::Controller] the controller scope
    #
    def helper(name, controller = nil)
      if controller
        matched_helpers = @helpers.select do |h|
          h.name == name.to_sym && (h.controller.nil? || h.controller == controller)
        end
      else
        matched_helpers = @helpers.select { |h| h.name == name.to_sym && h.controller.nil? }
      end
      matched_helpers.first
    end

    #
    # Return all the external errors which are registered for this base
    #
    # @return [Hash] a hash of external errors
    #
    def external_errors
      @external_errors ||= {}
    end

    #
    # Register a new external error
    #
    # @param error_class [Class] a class which should be caught
    #
    def register_external_error(error_class, &block)
      self.external_errors[error_class] = block
    end

  end
end
