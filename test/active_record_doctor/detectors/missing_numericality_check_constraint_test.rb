# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingNumericalityCheckConstraintTest < Minitest::Test
  def test_numericality_without_check_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 150 }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.age to enforce the numericality validator on Context::User.age - > 0 AND <= 150
    OUTPUT
  end

  def test_numericality_with_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 150 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_age_check CHECK (age > 0 AND age <= 150)
    SQL

    refute_problems
  end

  def test_numericality_greater_than_only
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :score, null: false
    end.define_model do
      validates :score, numericality: { greater_than: 0 }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.score to enforce the numericality validator on Context::User.score - > 0
    OUTPUT
  end

  def test_numericality_greater_than_with_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :score, null: false
    end.define_model do
      validates :score, numericality: { greater_than: 0 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_score_check CHECK (score > 0)
    SQL

    refute_problems
  end

  def test_numericality_greater_than_or_equal_to
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :quantity, null: false
    end.define_model do
      validates :quantity, numericality: { greater_than_or_equal_to: 1 }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.quantity to enforce the numericality validator on Context::User.quantity - >= 1
    OUTPUT
  end

  def test_numericality_greater_than_or_equal_to_with_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :quantity, null: false
    end.define_model do
      validates :quantity, numericality: { greater_than_or_equal_to: 1 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_quantity_check CHECK (quantity >= 1)
    SQL

    refute_problems
  end

  def test_numericality_less_than
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.float :rating, null: false
    end.define_model do
      validates :rating, numericality: { less_than: 5.0 }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.rating to enforce the numericality validator on Context::User.rating - < 5.0
    OUTPUT
  end

  def test_numericality_less_than_with_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.float :rating, null: false
    end.define_model do
      validates :rating, numericality: { less_than: 5.0 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_rating_check CHECK (rating < 5.0)
    SQL

    refute_problems
  end

  def test_numericality_less_than_or_equal_to
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :priority, null: false
    end.define_model do
      validates :priority, numericality: { less_than_or_equal_to: 10 }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.priority to enforce the numericality validator on Context::User.priority - <= 10
    OUTPUT
  end

  def test_numericality_less_than_or_equal_to_with_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :priority, null: false
    end.define_model do
      validates :priority, numericality: { less_than_or_equal_to: 10 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_priority_check CHECK (priority <= 10)
    SQL

    refute_problems
  end

  def test_numericality_only_integer
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :count, null: false
    end.define_model do
      validates :count, numericality: { only_integer: true, greater_than: 0 }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.count to enforce the numericality validator on Context::User.count - > 0 (integer only)
    OUTPUT
  end

  def test_numericality_only_integer_with_range_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :count, null: false
    end.define_model do
      validates :count, numericality: { only_integer: true, greater_than: 0 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_count_check CHECK (count > 0)
    SQL

    refute_problems
  end

  def test_numericality_without_range_options_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: true
    end

    refute_problems
  end

  def test_conditional_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0 }, if: :active?
    end

    refute_problems
  end

  def test_allow_nil_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age
    end.define_model do
      validates :age, numericality: { greater_than: 0, allow_nil: true }
    end

    refute_problems
  end

  def test_model_without_numericality_validators_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_model_with_non_existent_table_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.define_model(:User) do
      validates :age, numericality: { greater_than: 0 }
    end

    refute_problems
  end

  def test_config_ignore_models
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 150 }
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_numericality_check_constraint,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 150 }
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_numericality_check_constraint,
          ignore_attributes: ["Context::User.age"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 150 }
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_quoted_column_name_in_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :age, null: false
    end.define_model do
      validates :age, numericality: { greater_than: 0, less_than_or_equal_to: 150 }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_age_check CHECK ("age" > 0 AND "age" <= 150)
    SQL

    refute_problems
  end
end
