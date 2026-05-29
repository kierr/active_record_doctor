# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingEnumCheckConstraintTest < Minitest::Test
  def test_integer_enum_without_check_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1, archived: 2
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.status - the enum allows ["active", "inactive", "archived"] but the database accepts any value
    OUTPUT
  end

  def test_integer_enum_with_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status IN (0, 1))
    SQL

    refute_problems
  end

  def test_integer_enum_with_range_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1, archived: 2
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status >= 0 AND status <= 2)
    SQL

    refute_problems
  end

  def test_string_enum_without_check_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false, default: "viewer"
    end.define_model do
      enum :role, admin: "admin", editor: "editor", viewer: "viewer"
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.role - the enum allows ["admin", "editor", "viewer"] but the database accepts any value
    OUTPUT
  end

  def test_string_enum_with_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :role, null: false, default: "viewer"
    end.define_model do
      enum :role, admin: "admin", editor: "editor", viewer: "viewer"
    end

    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'editor', 'viewer'))
    SQL

    refute_problems
  end

  def test_model_without_enums_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_model_with_non_existent_table_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.define_model(:User) do
      enum :status, active: 0
    end

    refute_problems
  end

  def test_config_ignore_tables
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_enum_check_constraint,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.integer :status, null: false, default: 0
    end.define_model do
      enum :status, active: 0, inactive: 1
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_enum_check_constraint,
          ignore_columns: ["users.status"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

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
