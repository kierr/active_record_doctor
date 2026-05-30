# frozen_string_literal: true

require "active_record_doctor/detectors/base"

module ActiveRecordDoctor
  module Detectors
    class UrlColumnWithoutValidation < Base # :nodoc:
      @description = "detect _url and _uri columns without a format or URI validator"
      @config = {
        ignore_models: { description: "models whose columns should not be checked", global: true },
        ignore_attributes: { description: "attributes, written as Model.attribute, that should not be checked" }
      }

      private

      def message(**kwargs)
        "#{table}.#{column} stores URLs/URIs without a format validator — add format: { with: URI::DEFAULT_PARSER.make_regexp }"
      end

      def detect
        each_model(except: config(:ignore_models), existing_tables_only: true) do |model|
        each_attribute(model, except: config(:ignore_attributes), type: [:string, :text]) do |column|
          next unless column.name.match?(/(_url|_uri|\Aurl\z|\Auri\z)\z/i)

          has_format_validator = model.validators.any? do |v|
            v.kind == :format &&
              v.attributes.map(&:to_s).include?(column.name)
          end
          next if has_format_validator

          problem!(model: model.name, table: model.table_name, column: column.name)
        end
      end
      end
    end
  end
end
