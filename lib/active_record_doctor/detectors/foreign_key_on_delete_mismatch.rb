# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class ForeignKeyOnDeleteMismatch < Base # :nodoc:
      @description = "detect foreign key ON DELETE actions that mismatch AR dependent options"
      @config = {
        ignore_models: { description: "models whose associations should not be checked", global: true },
        ignore_associations: { description: "associations, written as Model.association, that should not be checked" }
      }

      private

      def message(**kwargs)
        "#{model}.#{association} has dependent: :#{dependent} but the FK on #{table} uses ON DELETE #{on_delete} — these should match"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
        each_association(model, except: config(:ignore_associations)) do |association|
          next unless [:has_many, :has_one].include?(association.macro)
          next if association.polymorphic?
          next if association.through_reflection?

          dependent = association.options[:dependent]
          next unless dependent

          begin
            fk = connection.foreign_keys(association.klass.table_name).find do |fk|
              fk.to_table == model.table_name
            end
          rescue StandardError
            next
          end
          next unless fk

          case dependent
          when :destroy, :destroy_async
            # AR will load and destroy each record — cascade would skip AR callbacks
            if fk.on_delete == :cascade
              problem!(model: model.name, association: association.name,
                       dependent: dependent, on_delete: fk.on_delete,
                       table: association.klass.table_name)
            end
          when :delete, :delete_all
            # AR skips callbacks — cascade is fine, but no on_delete is a mismatch
            if fk.on_delete.nil?
              problem!(model: model.name, association: association.name,
                       dependent: dependent, on_delete: "none",
                       table: association.klass.table_name)
            end
          when :nullify
            if fk.on_delete != :nullify
              problem!(model: model.name, association: association.name,
                       dependent: dependent, on_delete: fk.on_delete,
                       table: association.klass.table_name)
            end
          end
        end
      end
      end
    end
  end
end
