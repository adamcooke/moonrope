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
    attr_accessor :mutation

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

    def mutate(value)
      if mutation
        value ? value.public_send(mutation) : nil
      else
        auto_mutate(value)
      end
    end

    def auto_mutate(value)
      case value_type
      when :timestamp
        value.is_a?(Time) ? value.to_s : value
      when :unix_timestamp
        value.to_i
      else
        value
      end
    end

    def example
      @example ||= begin
        if value_type == :timestamp
          "2016-12-25 09:42:00 +0000"
        elsif value_type == :unix_timestamp
          "1491070507"
        elsif value_type == :boolean
          "false"
        elsif value_type == :uuid
          "017dabc1-3f4f-47ab-ab7d-86e2ed0de679"
        end
      end
    end

  end
end
