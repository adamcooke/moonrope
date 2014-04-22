module Moonrope
  class CoreDSL
    
    def self.load(path)
      object = self.new
      Dir["#{path}/**/*.rb"].each do |filename|
        object.instance_eval(File.read(filename), filename)
      end
      object
    end
    
    def structures
      @structures ||= []
    end
    
    def structure(name, &block)
      if block_given?
        structure = Structures::Structure.new(self, name)
        structure.dsl.instance_eval(&block)
        structures << structure
      else
        structures.select { |s| s.name == name }.first
      end
    end
    
  end
end
