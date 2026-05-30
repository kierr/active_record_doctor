# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class ExcessiveTableIndexes < Base # :nodoc:
      @description = "detect tables with an excessive number of indexes"
      @config = {
        ignore_tables: { description: "tables that should not be checked", global: true },
        max_indexes: { description: "maximum number of indexes per table before flagging" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table} has #{index_count} indexes (max: #{max}) — every index costs ~1.5TB at 100B rows and slows writes"
      end

      def detect
        max = config(:max_indexes).is_a?(Array) ? 8 : config(:max_indexes)
      each_table(except: config(:ignore_tables)) do |table|
        table_indexes = indexes(table)
        next if table_indexes.count <= max

        problem!(table: table, index_count: table_indexes.count, max: max,
                 indexes: table_indexes.map(&:name))
      end
      end
    end
  end
end
