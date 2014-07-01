module Moonrope
  class StructureAttribute
    
    attr_accessor :name
    attr_accessor :condition
    attr_accessor :group
    attr_accessor :source_attribute
    attr_accessor :description
    attr_accessor :value_type
    attr_accessor :structure
    attr_accessor :structure_opts
    
    def initialize(type, name, description)
      @type = type
      @name = name
      @description = description
    end
    
    def source_attribute
      @source_attribute || @name
    end
    
  end
end
