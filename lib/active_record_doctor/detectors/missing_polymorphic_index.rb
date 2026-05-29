# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class MissingPolymorphicIndex < Base # :nodoc:
      @description = "detect polymorphic associations without a composite index on type and id columns"
      @config = {
        ignore_models: {
          description: "models whose associations should not be checked",
          global: true
        },
        ignore_associations: {
          description: "associations, written as Model.association, that should not be checked"
        }
      }

      private

      def message(association:, model_name:, table:, type_column:, id_column:)
        "add a composite index on #{table}(#{type_column}, #{id_column}) - polymorphic association #{model_name}.#{association} is not indexed"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
          model.reflect_on_all_associations(:belongs_to).each do |reflection|
            next unless reflection.polymorphic?
            next if ignored?("#{model.name}.#{reflection.name}", config(:ignore_associations))

            type_column = reflection.foreign_type
            id_column = reflection.foreign_key
            next if polymorphic_index_exists?(model.table_name, type_column, id_column)

            problem!(
              association: reflection.name,
              model_name: model.name,
              table: model.table_name,
              type_column: type_column,
              id_column: id_column
            )
          end
        end
      end

      def polymorphic_index_exists?(table_name, type_column, id_column)
        connection.indexes(table_name).any? do |index|
          index.columns.is_a?(Array) &&
            index.columns.length >= 2 &&
            index.columns[0] == type_column &&
            index.columns[1] == id_column
        end
      end
    end
  end
end
