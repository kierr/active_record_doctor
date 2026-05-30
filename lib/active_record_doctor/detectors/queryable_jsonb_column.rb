# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class QueryableJsonbColumn < Base # :nodoc:
      @description = "detect JSONB columns with store_accessor that may be better as discrete columns"
      @config = {
        ignore_models: { description: "models whose columns should not be checked", global: true },
        ignore_attributes: { description: "attributes, written as Model.attribute, that should not be checked" }
      }

      private

      def message(model:, column:, accessors:, **kwargs)
        "#{model} uses store_accessor on #{column} with #{accessors.length} known keys — consider extracting to discrete columns for type safety and query performance"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
        next unless model.respond_to?(:stored_attributes)

        model.stored_attributes.each do |column_name, accessors|
          next if ignored?("#{model.name}.#{column_name}", config(:ignore_attributes))
          column = model.columns_hash[column_name.to_s]
          next unless column&.type == :jsonb
          next if accessors.length <= 2

          problem!(model: model.name, table: model.table_name, column: column_name,
                   accessors: accessors)
        end
      end
      end
    end
  end
end
