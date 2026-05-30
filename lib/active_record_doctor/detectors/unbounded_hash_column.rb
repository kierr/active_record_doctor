# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UnboundedHashColumn < Base # :nodoc:
      @description = "detect hash/digest columns without a fixed-length type or tight limit"
      @config = {
        ignore_tables: { description: "tables whose columns should not be checked", global: true },
        ignore_columns: { description: "columns, written as table.column, that should not be checked" }
      }

      private

      def message(table:, column: nil, **kwargs)
        "#{table}.#{column} stores a hash digest without a length cap — use char(N) or add a tight limit"
      end

      def detect
        each_table(except: config(:ignore_tables)) do |table|
        each_column(table) do |column|
          next if ignored?("#{table}.#{column.name}", config(:ignore_columns))
          next unless [:string, :text].include?(column.type)

          is_hash = column.name.match?(/(sha256|sha1|sha512|md5|checksum|digest|hash_value)\z/i)
          next unless is_hash

          # sha256 should be char(64), sha1 char(40), md5 char(32)
          next if column.limit && column.limit <= 128

          problem!(table: table, column: column.name)
        end
      end
      end
    end
  end
end
