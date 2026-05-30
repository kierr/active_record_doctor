# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class InconsistentCrossTableTypes < Base # :nodoc:
      @description = "detect columns with the same name but different types across tables"
      @config = {
        ignore_columns: { description: "columns, written as column_name, that should not be checked" }
      }

      private

      def message(column:, types:, **kwargs)
        "column #{column} has inconsistent types across tables: #{types.join(' vs ')}"
      end

      def detect
        col_types = Hash.new { |h, k| h[k] = [] }

      connection.tables.each do |table|
        connection.columns(table).each do |column|
          next if ["id", "type", "created_at", "updated_at"].include?(column.name)
          next if ignored?(column.name, config(:ignore_columns))
          col_types[column.name] << [table, column.sql_type, column.type]
        end
      end

      col_types.each do |name, entries|
        types = entries.map { |_, sql_type, _| sql_type }.uniq
        next if types.length <= 1
        next if entries.length < 2

        problem!(column: name, types: types,
                 tables: entries.map { |t, sql, _| "#{t}.#{sql}" })
      end
      end
    end
  end
end
