# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class JsonbWithoutShapeConstraint < Base # :nodoc:
      @description = "detect JSONB columns without a CHECK constraint enforcing jsonb_typeof"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} is JSONB without a CHECK(jsonb_typeof(...)) constraint — add shape enforcement"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless column.type == :jsonb

          constraints = check_constraints(table)
          has_shape = constraints.any? do |c|
            c =~ /jsonb_typeof\s*\(\s*#{Regexp.escape(column.name)}\s*\)/i
          end
          next if has_shape

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
