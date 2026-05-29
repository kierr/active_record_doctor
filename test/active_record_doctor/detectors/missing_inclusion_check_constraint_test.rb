# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingInclusionCheckConstraintTest < Minitest::Test
  def test_string_inclusion_without_check_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive", "archived"] }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.status to enforce the inclusion validator on Context::User.status - the validator allows ["active", "inactive", "archived"] but the database accepts any value
    OUTPUT
  end

  def test_integer_inclusion_without_check_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :role, null: false
    end.define_model do
      validates :role, inclusion: { in: [0, 1, 2] }
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.role to enforce the inclusion validator on Context::User.role - the validator allows [0, 1, 2] but the database accepts any value
    OUTPUT
  end

  def test_string_inclusion_with_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status IN ('active', 'inactive'))
    SQL

    refute_problems
  end

  def test_integer_inclusion_with_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :role, null: false
    end.define_model do
      validates :role, inclusion: { in: [0, 1] }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN (0, 1))
    SQL

    refute_problems
  end

  def test_string_inclusion_with_pg_normalized_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status::text = ANY(ARRAY['active'::character varying, 'inactive'::character varying]))
    SQL

    refute_problems
  end

  def test_integer_inclusion_with_array_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :role, null: false
    end.define_model do
      validates :role, inclusion: { in: [0, 1] }
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role = ANY(ARRAY[0, 1]))
    SQL

    refute_problems
  end

  def test_conditional_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }, if: :condition?
    end

    refute_problems
  end

  def test_unless_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }, unless: :condition?
    end

    refute_problems
  end

  def test_allow_nil_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }, allow_nil: true
    end

    refute_problems
  end

  def test_allow_blank_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }, allow_blank: true
    end

    refute_problems
  end

  def test_proc_in_validator_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ->(record) { ["active"] } }
    end

    refute_problems
  end

  def test_model_without_inclusion_validators_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_model_with_non_existent_table_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.define_model(:User) do
      validates :status, inclusion: { in: ["active"] }
    end

    refute_problems
  end

  def test_config_ignore_models
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_inclusion_check_constraint,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_attributes
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_inclusion_check_constraint,
          ignore_attributes: ["Context::User.status"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :status, null: false
    end.define_model do
      validates :status, inclusion: { in: ["active", "inactive"] }
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end
end
