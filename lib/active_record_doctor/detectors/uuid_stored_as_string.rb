# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UuidStoredAsString < Base # :nodoc:
      @description = "detect UUID values stored in string columns instead of the native uuid type"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} stores UUIDs as a string — use the native uuid type for validation and 16-byte storage"
      end

      def detect
        uuid_pattern = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

      each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless [:string, :text].include?(column.type)
          next unless column.default.present? && column.default.match?(uuid_pattern)

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
