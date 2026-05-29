# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects columns using the json type instead of jsonb.
    # jsonb supports indexing, efficient access, and operators.
    # json (the text-storage type) offers none of these.
    class JsonInsteadOfJsonb < Base
      @description = "detect columns using json instead of jsonb"
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

      def message(column:, table:)
        "change #{table}.#{column} from json to jsonb - jsonb supports indexing, efficient access, and operators; json does not"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          connection.columns(table).each do |column|
            next unless column.sql_type == "json"
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))

            problem!(column: column.name, table: table)
          end
        end
      end
    end
  end
end
