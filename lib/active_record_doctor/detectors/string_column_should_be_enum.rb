# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class StringColumnShouldBeEnum < Base # :nodoc:
      @description = "detect string columns with inclusion validators that should be Postgres enums"
      @config = {
        ignore_models: { description: "models whose columns should not be checked", global: true },
        ignore_attributes: { description: "attributes, written as Model.attribute, that should not be checked" }
      }

      private

      def message(table:, column:, values:, **kwargs)
        "#{table}.#{column} has an inclusion validator with #{values} string values — consider using a Postgres enum for 4-byte storage and DB-level enforcement"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
        model.validators.each do |validator|
          next unless validator.is_a?(ActiveModel::Validations::InclusionValidator)
          next if validator.options.key?(:if) || validator.options.key?(:unless)
          next if validator.options[:allow_nil] || validator.options[:allow_blank]

          values = validator.options[:in] || validator.options[:within]
          next unless values.is_a?(Array)
          next if values.length > 100
          next if values.any? { |v| !v.is_a?(String) }

          validator.attributes.each do |attribute|
            next if ignored?("#{model.name}.#{attribute}", config(:ignore_attributes))

            column = model.columns_hash[attribute.to_s]
            next unless column
            next unless [:string, :text].include?(column.type)

            problem!(model: model.name, table: model.table_name, column: attribute,
                     values: values.length)
          end
        end
      end
      end
    end
  end
end
