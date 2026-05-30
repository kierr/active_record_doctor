# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class NullableCounterCache < Base # :nodoc:
      @description = "detect counter cache columns that are nullable"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} is a counter cache that allows NULL — add NOT NULL DEFAULT 0"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless column.name.end_with?("_count")
          next unless column.null
          next unless column.default.present? && column.default.to_i == 0

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
