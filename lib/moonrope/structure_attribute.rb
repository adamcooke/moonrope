module Moonrope
  class StructureAttribute

    attr_accessor :name
    attr_accessor :groups
    attr_accessor :conditions
    attr_accessor :source_attribute
    attr_accessor :description
    attr_accessor :value_type
    attr_accessor :structure
    attr_accessor :structure_opts
    attr_accessor :value
    attr_accessor :example
    attr_accessor :doc

    def initialize(type, name)
      @type = type
      @name = name
      @groups = []
      @conditions = []
    end

    def source_attribute
      @source_attribute || @name
    end

    def name_with_groups
      ([groups] + [name]).flatten.compact.join('.')
    end

    def example
      @example ||= begin
        if value_type == :timestamp
          "2016-12-25 09:42:00 +0000"
        elsif value_type == :boolean
          "false"
        end
      end
    end

  end
end
