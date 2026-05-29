# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    # Detects Active Record attribute defaults not mirrored as column defaults
    # in PostgreSQL. AR applies defaults in Ruby via column_defaults or the
    # attribute API, but unless the database column also has a default, direct
    # SQL inserts will omit the value — resulting in NULL or constraint
    # violations instead of the expected default.
    class MissingDefaultInPg < Base # :nodoc:
      @description = "detect Active Record column defaults not mirrored in the database"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      private

      AUTO_MANAGED_COLUMNS = %w[id created_at updated_at created_on updated_on].freeze

      def message(column:, table:, ar_default:)
        "add a default to #{table}.#{column} in the database - Active Record sets it to #{ar_default.inspect} in Ruby but the column has no default in PostgreSQL"
      end

      def detect
        return unless Utils.postgresql?(connection)

        table_models = models.select(&:table_exists?).group_by(&:table_name)
        reported = Set.new

        table_models.each do |table, table_model_list|
          next if ignored?(table, config(:ignore_tables))

          ar_defaults = collect_ar_defaults(table, table_model_list)
          pg_defaults = collect_pg_defaults(table)

          (ar_defaults.keys - AUTO_MANAGED_COLUMNS).each do |column_name|
            next if ignored?("#{table}.#{column_name}", config(:ignore_columns))
            next if reported.include?("#{table}.#{column_name}")
            next if pg_defaults.key?(column_name)

            reported.add("#{table}.#{column_name}")

            problem!(
              column: column_name,
              table: table,
              ar_default: ar_defaults[column_name]
            )
          end
        end
      end

      def collect_ar_defaults(table, table_model_list)
        defaults = {}

        # Column defaults come from the schema (db/schema.rb or migrations).
        # These are already known to connection.columns but we read them from
        # model.column_defaults to capture per-model overrides.
        table_model_list.each do |model|
          model.column_defaults.each do |col_name, value|
            next if value.nil?
            defaults[col_name] ||= value
          end
        end

        # The attribute API (attribute :role, default: "viewer") registers
        # defaults in _default_attributes, which is separate from column_defaults.
        table_model_list.each do |model|
          next unless model.respond_to?(:_default_attributes)

          model._default_attributes.keys.each do |name|
            name = name.to_s
            next if defaults.key?(name)
            next unless connection.columns(table).any? { |c| c.name == name }

            attr = model._default_attributes[name]
            value = attr.value_before_type_cast
            next if value.nil?
            defaults[name] ||= value
          end
        end

        defaults
      end

      def collect_pg_defaults(table)
        defaults = {}

        # pg_attrdef stores column default expressions. Joining pg_attribute
        # gives us the column name; atthasdef is a fast flag that a default
        # exists.
        rows = connection.select_all(<<~SQL)
          SELECT a.attname, pg_get_expr(d.adbin, d.adrelid) AS default_expr
          FROM pg_attribute a
          JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
          JOIN pg_class c ON c.oid = a.attrelid
          WHERE c.relname = #{connection.quote(table)}
            AND a.attnum > 0
            AND NOT a.attisdropped
        SQL

        rows.each do |row|
          defaults[row["attname"]] = row["default_expr"]
        end

        defaults
      end
    end
  end
end
