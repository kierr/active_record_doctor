# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class InconsistentPrimaryKeyStrategy < Base # :nodoc:
      @description = "detect tables with primary key types that differ from related tables"
      @config = {
        ignore_tables: { description: "tables that should not be checked", global: true }
      }

      private

      def message(table:, pk_type:, dominant_type:, **kwargs)
        "#{table} uses #{pk_type} for its primary key but most tables use #{dominant_type} — consider migrating for consistency"
      end

      def detect
        pk_types = {}
      each_table(except: config(:ignore_tables)) do |table|
        pk_col = connection.columns(table).find { |c| c.name == "id" }
        next unless pk_col
        pk_types[table] = pk_col.sql_type
      end

      # Find the dominant PK type
      type_counts = pk_types.values.tally
      dominant_type = type_counts.max_by { |_, count| count }&.first

      pk_types.each do |table, pk_type|
        next if pk_type == dominant_type
        next if table == "schema_migrations"

        problem!(table: table, pk_type: pk_type, dominant_type: dominant_type)
      end
      end
    end
  end
end
