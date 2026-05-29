# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects float columns that should use decimal for precision or integer
    # for discrete values. Float is imprecise and unsuitable for financial,
    # statistical, or coordinate data at 100B-row scale.
    class FloatColumn < Base
      @description = "detect float columns that should use decimal for precision"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(column:, table:, suggestion:)
        "change #{table}.#{column} from float to #{suggestion} - float is imprecise and unsuitable for statistical, financial, or coordinate data"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          connection.columns(table).each do |column|
            next unless column.type == :float
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))

            suggestion = suggest_type(column)
            problem!(column: column.name, table: table, suggestion: suggestion)
          end
        end
      end

      def suggest_type(column)
        name = column.name
        if name.include?("rate") || name.include?("freq") || name.include?("score")
          "decimal"
        elsif name.include?("coord") || name.include?("lat") || name.include?("lon") || name == "area"
          "decimal"
        elsif name.include?("time") || name.include?("duration")
          "decimal or integer (milliseconds)"
        else
          "decimal"
        end
      end
    end
  end
end
