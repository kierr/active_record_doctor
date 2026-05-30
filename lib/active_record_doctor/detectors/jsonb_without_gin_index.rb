# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class JsonbWithoutGinIndex < Base # :nodoc:
      @description = "detect JSONB columns without a GIN index"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} is JSONB without a GIN index — add one if the column is queried with @>, ?, or ?| operators"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        table_indexes = indexes(table)
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless column.type == :jsonb

          has_gin = table_indexes.any? do |index|
            index.columns.include?(column.name) && index.using == "gin"
          end
          next if has_gin

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
