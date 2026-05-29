# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingStiTypeConstraintTest < Minitest::Test
  def test_sti_without_check_constraint
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :type, null: false
    end.define_model

    Context.define_model(:Client, Context::User)
    Context.define_model(:Admin, Context::User)

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.type - the STI model allows ["Context::Admin", "Context::Client", "Context::User"] but the database accepts any value
    OUTPUT
  end

  def test_sti_with_check_constraint_is_allowed
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :type, null: false
    end.define_model

    Context.define_model(:Client, Context::User)

    quoted_values = ["Context::Client", "Context::User"].sort.map { |v| ActiveRecord::Base.connection.quote(v) }.join(", ")
    Context.execute(<<~SQL)
      ALTER TABLE users ADD CONSTRAINT users_type_check CHECK (type IN (#{quoted_values}))
    SQL

    refute_problems
  end

  def test_model_without_sti_column_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_model_with_non_existent_table_is_skipped
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.define_model(:User)

    refute_problems
  end

  def test_sti_base_without_subclasses
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :type, null: false
    end.define_model

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.type - the STI model allows ["Context::User"] but the database accepts any value
    OUTPUT
  end

  def test_custom_inheritance_column
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :custom_type, null: false
    end.define_model do
      self.inheritance_column = :custom_type
    end

    Context.define_model(:Client, Context::User) do
      self.inheritance_column = :custom_type
    end

    assert_problems(<<~OUTPUT)
      add a CHECK constraint to users.custom_type - the STI model allows ["Context::Client", "Context::User"] but the database accepts any value
    OUTPUT
  end

  def test_config_ignore_tables
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :type, null: false
    end.define_model

    Context.define_model(:Client, Context::User)

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_sti_type_constraint,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :type, null: false
    end.define_model

    Context.define_model(:Client, Context::User)

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_sti_type_constraint,
          ignore_columns: ["users.type"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :type, null: false
    end.define_model

    Context.define_model(:Client, Context::User)

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
