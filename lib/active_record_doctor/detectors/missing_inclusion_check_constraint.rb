# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingInclusionCheckConstraint < Base # :nodoc:
      @description = "detect inclusion validators not backed by a database CHECK constraint"
      @config = {
        ignore_models: {
          description: "models whose validators should not be checked",
          global: true
        },
        ignore_attributes: {
          description: "attributes, written as Model.attribute, whose validators should not be checked"
        }
      }

      private

      def message(model:, table:, column:, values:)
        "add a CHECK constraint to #{table}.#{column} to enforce the inclusion validator on #{model}.#{column} - the validator allows #{values.inspect} but the database accepts any value"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          inclusion_validators(model).each do |validator|
            validator.attributes.each do |attribute|
              next if ignored?("#{model.name}.#{attribute}", config(:ignore_attributes))
              next if conditional?(validator)
              next if allow_nil_or_blank?(validator)

              values = extract_values(validator)
              next unless values.is_a?(Array)

              next if covered_by_check_constraint?(model.table_name, attribute, values)

              problem!(
                model: model.name,
                table: model.table_name,
                column: attribute,
                values: values
              )
            end
          end
        end
      end

      def inclusion_validators(model)
        model.validators.select do |validator|
          validator.is_a?(ActiveModel::Validations::InclusionValidator)
        end
      end

      def conditional?(validator)
        validator.options.key?(:if) || validator.options.key?(:unless)
      end

      def allow_nil_or_blank?(validator)
        validator.options[:allow_nil] == true || validator.options[:allow_blank] == true
      end

      def extract_values(validator)
        values = validator.options[:in] || validator.options[:within]
        values.is_a?(Proc) ? nil : values
      end

      def covered_by_check_constraint?(table_name, column_name, values)
        constraints = check_constraints(table_name)
        return false if constraints.empty?

        patterns = check_constraint_patterns(column_name, values)

        constraints.any? do |constraint|
          patterns.any? { |pattern| constraint =~ pattern }
        end
      end

      def check_constraint_patterns(column_name, values)
        quoted = connection.quote_column_name(column_name)
        escaped = Regexp.escape(column_name)

        if values.first.is_a?(Integer)
          int_values = values.sort
          [
            /#{quoted}\s+IN\s*\(\s*#{int_values.join('\s*,\s*')}\s*\)/i,
            /#{escaped}\s+IN\s*\(\s*#{int_values.join('\s*,\s*')}\s*\)/i,
            /#{quoted}\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{int_values.join('\s*,\s*')}\s*\]\s*\)/i,
            /#{escaped}\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{int_values.join('\s*,\s*')}\s*\]\s*\)/i
          ]
        else
          string_values = values.sort.map { |v| connection.quote(v) }
          bare_values = string_values.map { |v| Regexp.escape(v) }
          cast_values = string_values.map { |v| "#{Regexp.escape(v)}::[\\w ]+" }
          [
            /#{quoted}\s+IN\s*\(\s*#{bare_values.join('\s*,\s*')}\s*\)/i,
            /#{escaped}\s+IN\s*\(\s*#{bare_values.join('\s*,\s*')}\s*\)/i,
            /#{quoted}::text\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{cast_values.join('\s*,\s*')}\s*\]/i,
            /#{escaped}::text\s*=\s*ANY\s*\(\s*ARRAY\s*\[\s*#{cast_values.join('\s*,\s*')}\s*\]/i
          ]
        end
      end
    end
  end
end
