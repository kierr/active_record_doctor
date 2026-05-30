# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class NullableColumnWithDefault < Base # :nodoc:
      @description = "detect columns with a default value that are also nullable"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} has a default value (#{default}) but is nullable — add NOT NULL or remove the default"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next if column.name == "id"
          next unless column.default.present? && column.null

          problem!(table: table, column: column.name, default: column.default, type: column.sql_type)
        end
      end
      end
    end
  end
end
