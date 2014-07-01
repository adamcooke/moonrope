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
    
    def initialize(type, name, description)
      @type = type
      @name = name
      @description = description
      @groups = []
      @conditions = []
    end
    
    def source_attribute
      @source_attribute || @name
    end
    
  end
end
