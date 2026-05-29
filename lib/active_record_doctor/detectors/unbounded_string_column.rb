# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects string columns without explicit length caps that hold bounded
    # vocabulary data (status, kind, type, etc.). At 100B rows, every unbounded
    # string is a storage and index efficiency issue. These columns should
    # either have explicit limits or be converted to PG enums.
    class UnboundedStringColumn < Base
      @description = "detect string columns without length caps that hold bounded vocabulary data"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      # Column name patterns that indicate bounded vocabulary data.
      BOUNDED_PATTERNS = %w[
        status kind type format role level vendor brand country state
        protocol method category tier class scope channel source
        strategy engine platform stage phase mode action
      ].freeze

      private

      def message(column:, table:)
        "add a length cap or convert #{table}.#{column} to an enum - string column holds bounded vocabulary data but has no explicit limit"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          connection.columns(table).each do |column|
            next unless column.type == :string
            next if column.limit.present?
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
            next unless bounded_vocabulary?(column.name)

            problem!(column: column.name, table: table)
          end
        end
      end

      def bounded_vocabulary?(column_name)
        base = column_name.to_s

        BOUNDED_PATTERNS.any? do |pattern|
          base == pattern ||
            base.end_with?("_#{pattern}") ||
            base.start_with?("#{pattern}_")
        end
      end
    end
  end
end
