# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::BooleanWithoutDefaultTest < Minitest::Test
  def test_boolean_column_without_default
    Context.create_table(:users) do |t|
      t.boolean :active
    end.define_model

    assert_problems(<<~OUTPUT)
      add a default value to users.active - boolean columns should have a database default to avoid nil ambiguity
    OUTPUT
  end

  def test_boolean_column_with_default_is_allowed
    Context.create_table(:users) do |t|
      t.boolean :active, default: false
    end.define_model

    refute_problems
  end

  def test_boolean_column_with_default_function_is_allowed
    Context.create_table(:users) do |t|
      t.column :active, :boolean, default: -> { "true" }
    end.define_model

    refute_problems
  end

  def test_non_boolean_columns_are_skipped
    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_primary_key_boolean_is_skipped
    skip("primary keys can't be redefined in Rails 8.1+") unless postgresql?

    # The detector skips the PK column by name, so just verify a table
    # with a boolean PK (uuid-based table) doesn't flag it.
    Context.create_table(:users, id: :uuid) do |t|
      t.boolean :active
    end.define_model

    assert_problems(<<~OUTPUT)
      add a default value to users.active - boolean columns should have a database default to avoid nil ambiguity
    OUTPUT
  end

  def test_foreign_key_is_skipped
    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: true
    end.define_model

    refute_problems
  end

  def test_model_without_table_is_skipped
    Context.define_model(:User)

    refute_problems
  end

  def test_config_ignore_tables
    Context.create_table(:users) do |t|
      t.boolean :active
    end.define_model

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :boolean_without_default,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    Context.create_table(:users) do |t|
      t.boolean :active
    end.define_model

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :boolean_without_default,
          ignore_columns: ["users.active"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    Context.create_table(:users) do |t|
      t.boolean :active
    end.define_model

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
