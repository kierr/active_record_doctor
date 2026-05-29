# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects STI type columns not backed by a CHECK constraint restricting
    # values to valid class names. Without a database-level constraint, direct
    # SQL can set the type column to an invalid class name, causing errors on
    # record instantiation.
    class MissingStiTypeConstraint < Base # :nodoc:
      @description = "detect STI type columns not backed by a CHECK constraint on valid class names"
      @config = {
        ignore_tables: {
          description: "tables whose STI columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(column:, table:, class_names:)
        "add a CHECK constraint to #{table}.#{column} - the STI model allows #{class_names.sort.inspect} but the database accepts any value"
      end

      def detect
        return unless Utils.postgresql?(connection)

        table_models = models.select(&:table_exists?).group_by(&:table_name)
        reported = Set.new

        table_models.each do |table, table_model_list|
          next if ignored?(table, config(:ignore_tables))

          sti_models = table_model_list.select do |model|
            model.columns_hash.key?(model.inheritance_column.to_s)
          end

          next if sti_models.empty?

          # The base STI model is the one that owns the table and has the type
          # column. In single-table inheritance, all descendants share the same
          # table and type column.
          base_model = sti_models.find { |m| m.base_class? && m.table_name == table }
          base_model ||= sti_models.first

          type_column = base_model.inheritance_column.to_s
          next if ignored?("#{table}.#{type_column}", config(:ignore_columns))
          next if reported.include?("#{table}.#{type_column}")

          class_names = sti_models.flat_map do |model|
            [model.sti_name] + model.descendants.map(&:sti_name)
          end.uniq

          next if class_names.empty?
          next if sti_type_covered_by_check_constraint?(table, type_column, class_names)

          reported.add("#{table}.#{type_column}")

          problem!(
            column: type_column,
            table: table,
            class_names: class_names
          )
        end
      end

      def sti_type_covered_by_check_constraint?(table_name, column_name, class_names)
        constraints = check_constraints(table_name)
        return false if constraints.empty?

        quoted = connection.quote_column_name(column_name)
        escaped = Regexp.escape(column_name)
        string_values = class_names.sort.map { |v| connection.quote(v) }
        bare_values = string_values.map { |v| Regexp.escape(v) }
        cast_values = string_values.map { |v| "#{Regexp.escape(v)}::[\\w ]+" }

        expected_patterns = [
          # CHECK (type IN ('Base', 'Child'))
          /#{quoted}\s+IN\s*\(\s*#{bare_values.join('\s*,\s*')}\s*\)/i,
          /#{escaped}\s+IN\s*\(\s*#{bare_values.join('\s*,\s*')}\s*\)/i,
          # CHECK (type::text = ANY(ARRAY['Base'::character varying, ...]))
          /#{quoted}::text\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{cast_values.join('\s*,\s*')}\s*\]/i,
          /#{escaped}::text\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{cast_values.join('\s*,\s*')}\s*\]/i
        ]

        constraints.any? do |constraint|
          expected_patterns.any? { |pattern| constraint =~ pattern }
        end
      end
    end
  end
end
