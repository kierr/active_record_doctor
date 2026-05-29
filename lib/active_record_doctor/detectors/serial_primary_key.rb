# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects tables using serial primary keys instead of identity columns.
    # serial is a legacy macro with ownership and permission quirks;
    # bigint generated always as identity is the SQL-standard replacement.
    class SerialPrimaryKey < Base
      @description = "detect tables using serial primary keys instead of identity columns"
      @config = {
        ignore_tables: {
          description: "tables that should not be checked",
          global: true
        }
      }

      private

      def message(table:)
        "replace serial primary key on #{table} with bigint generated always as identity - serial is a legacy macro with ownership and permission quirks"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          pk_name = connection.primary_key(table)
          next unless pk_name

          column = connection.columns(table).find { |c| c.name == pk_name }
          next unless column
          next unless column.sql_type == "integer"

          default_fn = column.default_function.to_s
          next unless default_fn.include?("nextval")
          next if default_fn.include?("identity")

          problem!(table: table)
        end
      end
    end
  end
end
