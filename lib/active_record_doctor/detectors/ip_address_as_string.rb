# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects string columns storing IP addresses that should use the
    # PostgreSQL inet type. inet validates format, supports network
    # operations, and stores compactly (7 bytes IPv4 vs ~49 bytes varchar).
    class IpAddressAsString < Base
      @description = "detect string columns storing IP addresses that should use inet"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      IP_PATTERNS = /\A(ip_address|remote_ip|client_ip|source_ip|forwarded_ip|originating_ip)\z/

      private

      def message(column:, table:)
        "change #{table}.#{column} from string to inet - inet validates format, supports network operations, and stores compactly"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_table(except: config(:ignore_tables)) do |table|
          connection.columns(table).each do |column|
            next unless column.type == :string
            next if column.sql_type == "inet"
            next unless column.name.match?(IP_PATTERNS)
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))

            problem!(column: column.name, table: table)
          end
        end
      end
    end
  end
end
