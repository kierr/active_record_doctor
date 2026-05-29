# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingNumericalityCheckConstraint < Base # :nodoc:
      @description = "detect numericality validators not backed by a database CHECK constraint"
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

      RANGE_OPTIONS = [:greater_than, :greater_than_or_equal_to, :less_than, :less_than_or_equal_to].freeze

      def message(model:, table:, column:, constraint_description:)
        "add a CHECK constraint to #{table}.#{column} to enforce the numericality validator on #{model}.#{column} - #{constraint_description}"
      end

      def detect
        return unless Utils.postgresql?(connection)

        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          numericality_validators(model).each do |validator|
            validator.attributes.each do |attribute|
              next if ignored?("#{model.name}.#{attribute}", config(:ignore_attributes))
              next if conditional?(validator)
              next if allow_nil?(validator)

              range_options = extract_range_options(validator)
              next if range_options.empty?

              only_integer = validator.options[:only_integer] == true
              constraint_description = describe_constraint(range_options, only_integer)

              next if covered_by_check_constraint?(model.table_name, attribute, range_options, only_integer)

              problem!(
                model: model.name,
                table: model.table_name,
                column: attribute,
                constraint_description: constraint_description
              )
            end
          end
        end
      end

      def numericality_validators(model)
        model.validators.select do |validator|
          validator.is_a?(ActiveModel::Validations::NumericalityValidator)
        end
      end

      def conditional?(validator)
        validator.options.key?(:if) || validator.options.key?(:unless)
      end

      def allow_nil?(validator)
        validator.options[:allow_nil] == true
      end

      def extract_range_options(validator)
        RANGE_OPTIONS.each_with_object({}) do |option, hash|
          hash[option] = validator.options[option] if validator.options.key?(option)
        end
      end

      def describe_constraint(range_options, only_integer)
        parts = range_options.map do |option, value|
          case option
          when :greater_than            then "> #{value}"
          when :greater_than_or_equal_to then ">= #{value}"
          when :less_than               then "< #{value}"
          when :less_than_or_equal_to    then "<= #{value}"
          end
        end
        description = parts.join(" AND ")
        description += " (integer only)" if only_integer
        description
      end

      def covered_by_check_constraint?(table_name, column_name, range_options, only_integer)
        constraints = check_constraints(table_name)
        return false if constraints.empty?

        patterns = check_constraint_patterns(column_name, range_options, only_integer)

        constraints.any? do |constraint|
          patterns.any? { |pattern| constraint =~ pattern }
        end
      end

      def check_constraint_patterns(column_name, range_options, only_integer)
        quoted = connection.quote_column_name(column_name)
        escaped = Regexp.escape(column_name)

        patterns = range_options.map do |option, value|
          case option
          when :greater_than
            [
              /#{quoted}\s*>\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i,
              /#{escaped}\s*>\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i
            ]
          when :greater_than_or_equal_to
            [
              /#{quoted}\s*>=\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i,
              /#{escaped}\s*>=\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i
            ]
          when :less_than
            [
              /#{quoted}\s*<\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i,
              /#{escaped}\s*<\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i
            ]
          when :less_than_or_equal_to
            [
              /#{quoted}\s*<=\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i,
              /#{escaped}\s*<=\s*#{Regexp.escape(value.to_s)}(?:\s|::|\)|$)/i
            ]
          end
        end.flatten

        if only_integer
          patterns + integer_cast_patterns(quoted, escaped)
        else
          patterns
        end
      end

      def integer_cast_patterns(quoted, escaped)
        [
          /#{quoted}\s*=\s*#{escaped}::integer/i,
          /\(#{quoted}\s*=\s*#{quoted}::integer\)/i,
          /#{escaped}\s*=\s*#{escaped}::integer/i,
          /\(#{escaped}\s*=\s*#{escaped}::integer\)/i,
          /#{quoted}::text\s*~\s*'\^-?\d+\$'/i,
          /#{escaped}::text\s*~\s*'\^-?\d+\$'/i,
          /#{quoted}\s*=\s*floor\s*\(\s*#{quoted}\s*\)/i,
          /#{escaped}\s*=\s*floor\s*\(\s*#{escaped}\s*\)/i
        ]
      end
    end
  end
end
