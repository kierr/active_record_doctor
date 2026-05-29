# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects Active Record enum declarations not backed by a database CHECK
    # constraint or native Postgres enum type. Without a database-level
    # constraint, direct SQL can set enum columns to arbitrary values, causing
    # Enum::ValidationError on read and permanently breaking the row.
    class MissingEnumCheckConstraint < Base # :nodoc:
      @description = "detect enum columns not backed by a database CHECK constraint or native enum type"
      @config = {
        ignore_tables: {
          description: "tables whose enum columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      def message(column:, table:, values:)
        "add a CHECK constraint to #{table}.#{column} - the enum allows #{values.inspect} but the database accepts any value"
      end

      def detect
        return unless Utils.postgresql?(connection)

        table_models = models.select(&:table_exists?).group_by(&:table_name)
        reported = Set.new

        table_models.each do |table, table_model_list|
          next if ignored?(table, config(:ignore_tables))

          # Collect all enum definitions across all models backing this table.
          all_enums = {}
          table_model_list.each do |model|
            model.defined_enums.each do |column_name, mapping|
              all_enums[column_name] ||= mapping
            end
          end

          next if all_enums.empty?

          all_enums.each do |column_name, mapping|
            next if ignored?("#{table}.#{column_name}", config(:ignore_columns))
            next if reported.include?("#{table}.#{column_name}")
            next if enum_backed_by_postgres_enum?(table, column_name)
            next if enum_covered_by_check_constraint?(table, column_name, mapping)

            reported.add("#{table}.#{column_name}")

            problem!(
              column: column_name,
              table: table,
              values: mapping.keys
            )
          end
        end
      end

      def enum_backed_by_postgres_enum?(table_name, column_name)
        connection.select_value(
          "SELECT t.typname FROM pg_type t " \
          "JOIN pg_attribute a ON a.atttypid = t.oid " \
          "JOIN pg_class c ON c.oid = a.attrelid " \
          "WHERE c.relname = #{connection.quote(table_name)} " \
          "AND a.attname = #{connection.quote(column_name)} " \
          "AND t.typtype = 'e'"
        ).present?
      end

      def enum_covered_by_check_constraint?(table_name, column_name, mapping)
        constraints = check_constraints(table_name)
        return false if constraints.empty?

        values = mapping.values
        expected_patterns = check_constraint_patterns(column_name, values)

        constraints.any? do |constraint|
          expected_patterns.any? { |pattern| constraint =~ pattern }
        end
      end

      def check_constraint_patterns(column_name, values)
        quoted = connection.quote_column_name(column_name)
        escaped = Regexp.escape(column_name)

        if values.first.is_a?(Integer)
          int_values = values.sort
          int_list = int_values.join(",")
          [
            # CHECK (col IN (0, 1, 2))
            /#{quoted}\s+IN\s*\(\s*#{int_values.join('\s*,\s*')}\s*\)/i,
            /#{escaped}\s+IN\s*\(\s*#{int_values.join('\s*,\s*')}\s*\)/i,
            # CHECK (col >= 0 AND col <= 2)
            /#{quoted}\s+>=\s*#{int_values.first}\s+AND\s+#{quoted}\s+<=\s*#{int_values.last}/i,
            /#{escaped}\s+>=\s*#{int_values.first}\s+AND\s+#{escaped}\s+<=\s*#{int_values.last}/i,
            # CHECK (col = ANY(ARRAY[0, 1, 2]))
            /#{quoted}\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{int_values.join('\s*,\s*')}\s*\]\s*\)/i,
            /#{escaped}\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{int_values.join('\s*,\s*')}\s*\]\s*\)/i
          ]
        else
          string_values = values.sort.map { |v| connection.quote(v) }
          # PG normalizes string CHECK constraints: the bare values in
          # 'admin'::character varying form must match the quoted strings.
          bare_values = string_values.map { |v| Regexp.escape(v) }
          cast_values = string_values.map { |v| "#{Regexp.escape(v)}::[\\w ]+" }
          [
            # CHECK (col IN ('a', 'b'))
            /#{quoted}\s+IN\s*\(\s*#{bare_values.join('\s*,\s*')}\s*\)/i,
            /#{escaped}\s+IN\s*\(\s*#{bare_values.join('\s*,\s*')}\s*\)/i,
            # CHECK (col::text = ANY(ARRAY['a'::character varying, ...]))
            /#{quoted}::text\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{cast_values.join('\s*,\s*')}\s*\]/i,
            /#{escaped}::text\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{cast_values.join('\s*,\s*')}\s*\]/i
          ]
        end
      end
    end
  end
end
