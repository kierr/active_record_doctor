# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UnboundedVarcharColumn < Base # :nodoc:
      @description = "detect varchar columns without a length limit and without a length validator"
      @config = {
        ignore_models: { description: "models whose columns should not be checked", global: true },
        ignore_attributes: { description: "attributes, written as Model.attribute, that should not be checked" }
      }

      private

      def message(table:, column:, **kwargs)
        "#{table}.#{column} has no length limit in the schema and no length validator — add a limit or a length validator"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
        each_attribute(model, except: config(:ignore_attributes), type: [:string, :text]) do |column|
          next if column.limit.present?

          has_length_validator = model.validators.any? do |v|
            v.kind == :length &&
              v.options[:maximum].present? &&
              v.attributes.map(&:to_s).include?(column.name)
          end
          next if has_length_validator

          problem!(model: model.name, table: model.table_name, column: column.name)
        end
      end
      end
    end
  end
end
