# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class BooleanWithoutDefault < Base # :nodoc:
      @description = "detect boolean columns without a database default value"
      @config = {
        ignore_tables: {
          description: "tables whose boolean columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(column:, table:)
        "add a default value to #{table}.#{column} - boolean columns should have a database default to avoid nil ambiguity"
      end

      def detect
        each_model(existing_tables_only: true) do |model|
          table = model.table_name
          next if ignored?(table, config(:ignore_tables))

          pk_name = connection.primary_key(table)

          connection.columns(table).each do |column|
            next unless column.type == :boolean
            next if column.name == pk_name
            next if looks_like_foreign_key?(column)
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
            next unless column.default.nil? && column.default_function.nil?

            problem!(column: column.name, table: table)
          end
        end
      end
    end
  end
end
