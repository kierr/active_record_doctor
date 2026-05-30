# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class AmountWithoutPositiveCheck < Base # :nodoc:
      @description = "detect amount/money columns without a CHECK constraint for positive values"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column:, **kwargs)
        "#{table}.#{column} stores monetary/amount data without a CHECK >= 0 constraint — negative values may be invalid"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless [:integer, :decimal].include?(column.type)
          next unless column.name.match?(/(amount|price|cost|fee|balance|total|payment|charge|revenue|salary|wage|rate)\z/i)

          constraints = check_constraints(table)
          has_positive = constraints.any? do |c|
            c =~ /#{Regexp.escape(column.name)}\s*>=\s*0/i ||
              c =~ /#{Regexp.escape(column.name)}\s*>\s*0/i
          end
          next if has_positive

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
