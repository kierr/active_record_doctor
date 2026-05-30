# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class EmailWithoutCaseInsensitiveIndex < Base # :nodoc:
      @description = "detect email columns with case-sensitive unique indexes"
      @config = {
        ignore_models: { description: "models whose columns should not be checked", global: true },
        ignore_attributes: { description: "attributes, written as Model.attribute, that should not be checked" }
      }

      private

      def message(table:, column:, index:, **kwargs)
        "#{table}.#{column} has a case-sensitive unique index (#{index}) — emails are case-insensitive, use citext or a LOWER() expression index"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
        each_attribute(model, except: config(:ignore_attributes), type: [:string, :text]) do |column|
          next unless column.name.match?(/email/i)

          table_indexes = indexes(model.table_name)
          email_index = table_indexes.find do |index|
            index.columns.length == 1 &&
              (index.columns.first.to_s == column.name || index.columns == [column.name]) &&
              index.unique
          end
          next unless email_index

          # Check if there's a LOWER() expression index
          has_expression = table_indexes.any? do |index|
            index.columns.is_a?(String) &&
              index.columns =~ /lower\s*\(\s*#{Regexp.escape(column.name)}\s*\)/i &&
              index.unique
          end
          next if has_expression

          # Check if column is citext
          next if column.sql_type == "citext"

          problem!(model: model.name, table: model.table_name, column: column.name,
                   index: email_index.name)
        end
      end
      end
    end
  end
end
