# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class NullableBoolean < Base # :nodoc:
      @description = "detect boolean columns that allow NULL (3-state booleans are an anti-pattern)"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} is a nullable boolean — use NOT NULL with a default, or convert to an enum for 3+ states"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless column.type == :boolean && column.null

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
