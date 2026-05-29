# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class DatetimeWithoutTimezone < Base # :nodoc:
      @description = "detect timestamp columns defined without timezone"
      @config = {
        ignore_tables: {
          description: "tables whose timestamp columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      TIMESTAMP_CONVENTION_COLUMNS = %w[created_at updated_at created_on updated_on].freeze

      def message(column:, table:)
        "change the type of #{table}.#{column} to `t.timestamp` (with time zone) - storing timestamps without timezone loses zone information"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          connection.columns(table).each do |column|
            next unless column.type == :datetime || column.type == :timestamptz
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
            next if TIMESTAMP_CONVENTION_COLUMNS.include?(column.name)
            next if column.sql_type.include?("with time zone")

            problem!(column: column.name, table: table)
          end
        end
      end
    end
  end
end
