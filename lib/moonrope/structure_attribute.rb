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
          "2016-02-02 09:54:19 +0000"
        elsif value_type == :boolean
          "true"
        end
      end
    end

    def friendly_value_type
      if @value_type.is_a?(Symbol)
        @value_type.to_s.capitalize
      else
        @value_type.to_s
      end
    end

  end
end
