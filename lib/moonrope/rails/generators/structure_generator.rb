module Moonrope
  class StructureGenerator < Rails::Generators::Base
    desc "Create a structure from an ActiveRecord model"
    argument :model_name, :type => :string, :description => "Name of model you wish to generate a struct for"
    class_option :recurse, :type => :boolean, :default => false, :description => "Recurse into linked models"

    def call
      begin
        @klass_name = model_name.constantize
      rescue NameError
        puts "#{model_name} could not be found"
      end

      puts "structure :#{structure_name(@klass_name)} do"
      @klass_name.content_columns.each do |column|
        puts build_content_column(column)
      end
      puts "end"
    end

    private

    def build_content_column(column, extent="full")
      type = column_type_to_class(column.type)
      "  #{extent} :#{column.name}, \"#{column.name.humanize} for #{@klass_name.model_name.human}\", :type => #{type}"
    end

    def column_type_to_class(type)
      case type
      when :integer, :boolean           then Integer
      when :float, :decimal             then Float
      when :datetime, :timestamp, :time then Time
      when :date                        then Date
      else String
      end
    end

    def default_basic_fields
      [@klass_name.primary_key, "name", "permalink", "slug", "description"]
    end

    def structure_name(klass)
      klass.model_name.demodulize.underscore
    end

  end
end
