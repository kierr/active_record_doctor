# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class IntegerShouldBeSmallint < Base # :nodoc:
      @description = "detect integer columns where smallint would suffice based on enum or validator bounds"
      @config = {
        ignore_tables: {
          description: "tables whose columns should not be checked",
          global: true
        },
        ignore_columns: {
          description: "columns, written as table.column, that should not be checked"
        }
      }

      SMALLINT_MAX = 32_767

      private

      def message(column:, table:, reason:)
        "change the type of #{table}.#{column} to smallint - #{reason}"
      end

      def detect
        return unless Utils.postgresql?(connection)

        table_models = models.select(&:table_exists?).group_by(&:table_name)

        table_models.each do |table, table_model_list|
          next if ignored?(table, config(:ignore_tables))

          connection.columns(table).each do |column|
            next if column.type != :integer
            next if column.sql_type != "integer"
            next if ignored?("#{table}.#{column.name}", config(:ignore_columns))

            reason = smallint_reason(table_model_list, column)
            next unless reason

            problem!(column: column.name, table: table, reason: reason)
          end
        end
      end

      def smallint_reason(table_model_list, column)
        enum_max = max_value_from_enums(table_model_list, column)
        if enum_max
          return nil if enum_max > SMALLINT_MAX

          return "enum values reach #{enum_max} which fits in smallint"
        end

        validator_max = max_value_from_numericality_validators(table_model_list, column)
        if validator_max
          return nil if validator_max > SMALLINT_MAX

          return "numericality validator allows up to #{validator_max} which fits in smallint"
        end

        nil
      end

      def max_value_from_enums(table_model_list, column)
        all_values = table_model_list.flat_map do |model|
          mapping = model.defined_enums[column.name]
          mapping ? mapping.values : []
        end

        return nil if all_values.empty?

        all_values.compact.max
      end

      def max_value_from_numericality_validators(table_model_list, column)
        bounds = table_model_list.flat_map do |model|
          numericality_upper_bounds(model, column.name.to_sym)
        end

        return nil if bounds.empty?

        bounds.max
      end

      def numericality_upper_bounds(model, column)
        model.validators.select do |validator|
          validator.kind == :numericality &&
            validator.attributes.include?(column)
        end.flat_map do |validator|
          options = validator.options
          less_than = options[:less_than]
          less_than_or_equal_to = options[:less_than_or_equal_to]

          upper_bounds = []
          upper_bounds << less_than if less_than
          upper_bounds << less_than_or_equal_to if less_than_or_equal_to
          upper_bounds
        end
      end
    end
  end
end
