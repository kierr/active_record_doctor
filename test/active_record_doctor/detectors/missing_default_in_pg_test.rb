# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingDefaultInPgTest < Minitest::Test
  def test_column_default_not_mirrored_in_pg
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false
      t.string :name, null: false
    end.define_model do
      attribute :role, default: "viewer"
    end

    assert_problems(<<~OUTPUT)
      add a default to users.role in the database - Active Record sets it to "viewer" in Ruby but the column has no default in PostgreSQL
    OUTPUT
  end

  def test_column_default_mirrored_in_pg_is_allowed
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false, default: "viewer"
    end.define_model do
      attribute :role, default: "viewer"
    end

    refute_problems
  end

  def test_schema_column_default_not_mirrored_in_pg
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    # column_defaults picks up the migration-level default even without
    # the attribute API. If the PG column somehow loses its default while
    # the AR schema still declares one, we flag it.
    Context.create_table(:users) do |t|
      t.string :role, null: false
      t.string :name, null: false
    end.define_model do
      # No attribute API call; column_defaults is empty for :role
      # because no default was set in the migration either. This model
      # should NOT be flagged.
    end

    refute_problems
  end

  def test_auto_managed_columns_are_skipped
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.timestamps null: false
    end.define_model

    refute_problems
  end

  def test_model_without_defaults_is_skipped
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_model_with_non_existent_table_is_skipped
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.define_model(:User)

    refute_problems
  end

  def test_config_ignore_tables
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false
    end.define_model do
      attribute :role, default: "viewer"
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_default_in_pg,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false
    end.define_model do
      attribute :role, default: "viewer"
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_default_in_pg,
          ignore_columns: ["users.role"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    skip("#{current_adapter} is not PostgreSQL") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false
    end.define_model do
      attribute :role, default: "viewer"
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
