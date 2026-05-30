# frozen_string_literal: true

ActiveRecordDoctor.configure do
  global :ignore_tables, [
    "ar_internal_metadata",
    "schema_migrations",
    "active_storage_blobs",
    "active_storage_attachments",
    "action_text_rich_texts"
  ]

  detector :extraneous_indexes,
    enabled: true,
    ignore_tables: [],
    ignore_indexes: []

  detector :incorrect_boolean_presence_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :incorrect_length_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :incorrect_dependent_option,
    enabled: true,
    ignore_models: [],
    ignore_associations: []

  detector :mismatched_foreign_key_type,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_foreign_keys,
    enabled: true,
    ignore_models: [],
    ignore_associations: []

  detector :missing_non_null_constraint,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_presence_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: [],
    ignore_columns_with_default: false

  detector :missing_unique_indexes,
    enabled: true,
    ignore_models: [],
    ignore_columns: [],
    ignore_join_tables: []

  detector :short_primary_key_type,
    enabled: true,
    ignore_tables: []

  detector :table_without_primary_key,
    enabled: true,
    ignore_tables: []

  detector :table_without_timestamps,
    enabled: true,
    ignore_tables: []

  detector :undefined_table_references,
    enabled: true,
    ignore_models: []

  detector :unindexed_deleted_at,
    enabled: true,
    ignore_tables: [],
    ignore_columns: [],
    ignore_indexes: [],
    column_names: ["deleted_at", "discarded_at"]

  detector :unindexed_foreign_keys,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_enum_check_constraint,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_inclusion_check_constraint,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :missing_numericality_check_constraint,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :missing_default_in_pg,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :missing_polymorphic_index,
    enabled: true,
    ignore_models: [],
    ignore_associations: []

  detector :missing_sti_type_constraint,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :boolean_without_default,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :integer_should_be_smallint,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :datetime_without_timezone,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :float_column,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :serial_primary_key,
    enabled: true,
    ignore_tables: []

  detector :json_instead_of_jsonb,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :ip_address_as_string,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :unbounded_string_column,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :nullable_column_with_default,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :nullable_boolean,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :nullable_counter_cache,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :uuid_stored_as_string,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :unbounded_hash_column,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :jsonb_without_shape_constraint,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :jsonb_without_gin_index,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :excessive_table_indexes,
    enabled: true,
    ignore_tables: [],
    max_indexes: 8

  detector :string_column_should_be_enum,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :unbounded_varchar_column,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :foreign_key_on_delete_mismatch,
    enabled: true,
    ignore_models: [],
    ignore_associations: []

  detector :url_column_without_validation,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :amount_without_positive_check,
    enabled: true,
    ignore_tables: [],
    ignore_columns: []

  detector :email_without_case_insensitive_index,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :queryable_jsonb_column,
    enabled: true,
    ignore_models: [],
    ignore_attributes: []

  detector :inconsistent_primary_key_strategy,
    enabled: true,
    ignore_tables: []

  detector :inconsistent_cross_table_types,
    enabled: true,
    ignore_columns: []
end
