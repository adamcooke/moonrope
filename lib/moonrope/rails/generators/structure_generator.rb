module Moonrope
  class StructureGenerator < Rails::Generators::Base
    desc "Create a structure from an ActiveRecord model"
    argument :model_name, :type => :string, :description => "Name of model you wish to generate a struct for"
    class_option :recurse, :type => :boolean, :default => false, :description => "Recurse into linked models"

    attr_reader :structures_generated

    desc "Create a structure from an ActiveRecord model"
    def call
      @structures_generated = []

      model = model_name.constantize
      StructureBuilder.build(self, model, options)
    end

    no_tasks do
      def write_structure(name, contents)
        unless @structures_generated.include?(name)
          create_file("api/structures/#{name}_struct.rb", contents)
          @structures_generated << name
        end
      end
    end

    private

    class StructureBuilder

      DEFAULT_BASIC_FIELDS = ["name", "permalink", "slug", "description", "subject", "identifier"]

      attr_reader :klass, :generator

      def self.build(generator, model_name, options={})
        self.new(generator, model_name, options).build
      end

      def initialize(generator, klass, options={})
        @generator = generator
        @klass = klass
        @options = options
        @to_build = []
      end

      def structure_name
        @structure_name ||= klass.model_name.demodulize.underscore
      end

      def build
        contents = Array.new.tap do |lines|
          lines << "structure :#{structure_name} do"

          basic_cols, full_cols = klass.columns.reject {|c| c.name =~ /_id$/ }.partition {|c| basic_field?(c.name) }

          basic_cols.each do |column|
            lines << build_content_column(column, "basic")
          end
          lines << ""

          full_cols.each do |column|
            lines << build_content_column(column, "full")
          end
          lines << ""

          klass.reflections.each do |relation_name, column|
            unless column.options[:polymorphic]
              builder = self.class.new(generator, column.klass, @options)
              @to_build << builder if @options['recurse']
              lines << build_relation_column(column, builder.structure_name, "expansion")
            end
          end

          lines << "end"
        end.join("\n")

        generator.write_structure(structure_name, contents)

        @to_build.each do |builder|
          builder.build unless generator.structures_generated.include?(builder.structure_name)
        end
      end

      private

      def build_content_column(column, extent)
        type = column_type_to_class(column.type)
        "  #{extent} :#{column.name}, \"#{column.name.humanize} for #{klass.model_name.human}\", :type => #{type}"
      end

      def build_relation_column(column, structure_name, extent)
        "  #{extent} :#{column.name}, \"#{column.name.to_s.humanize} for #{klass.model_name.human}\", :structure => :#{structure_name}"
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

      def basic_field?(col_name)
        basic_fields.include?(col_name)
      end

      def basic_fields
        @basic_fields ||= [klass.primary_key] + DEFAULT_BASIC_FIELDS
      end

    end

  end
end
