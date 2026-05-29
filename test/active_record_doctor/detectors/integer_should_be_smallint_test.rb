# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::IntegerShouldBeSmallintTest < Minitest::Test
  def test_integer_enum_with_small_values_is_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1, archived: 2
    end

    assert_problems(<<~OUTPUT)
      change the type of users.status to smallint - enum values reach 2 which fits in smallint
    OUTPUT
  end

  def test_integer_enum_with_large_values_is_not_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :category, null: false, default: 0
    end.define_model do
      enum :category, a: 0, b: 100_000
    end

    refute_problems
  end

  def test_numericality_validator_with_small_max_is_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :priority, null: false, default: 0
    end.define_model do
      validates :priority, numericality: { less_than_or_equal_to: 10 }
    end

    assert_problems(<<~OUTPUT)
      change the type of users.priority to smallint - numericality validator allows up to 10 which fits in smallint
    OUTPUT
  end

  def test_numericality_validator_with_large_max_is_not_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :score, null: false, default: 0
    end.define_model do
      validates :score, numericality: { less_than_or_equal_to: 100_000 }
    end

    refute_problems
  end

  def test_bigint_column_is_not_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.bigint :count, null: false, default: 0
    end.define_model do
      validates :count, numericality: { less_than_or_equal_to: 10 }
    end

    refute_problems
  end

  def test_smallint_column_is_not_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :status, :smallint, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    refute_problems
  end

  def test_integer_without_enum_or_validator_is_not_reported
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :amount, null: false, default: 0
    end.define_model

    refute_problems
  end

  def test_model_without_table_is_skipped
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.define_model(:User) do
      enum :status, active: 0
    end

    refute_problems
  end

  def test_config_ignore_tables
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :integer_should_be_smallint,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :integer_should_be_smallint,
          ignore_columns: ["users.status"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    skip("#{current_adapter} doesn't support column types") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
