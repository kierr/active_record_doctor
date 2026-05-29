# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::DatetimeWithoutTimezoneTest < Minitest::Test
  def test_datetime_without_timezone
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :published_at, :datetime
    end.define_model

    assert_problems(<<~OUTPUT)
      change the type of users.published_at to `t.timestamp` (with time zone) - storing timestamps without timezone loses zone information
    OUTPUT
  end

  def test_timestamp_with_timezone_is_not_reported
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :published_at, :timestamptz
    end.define_model

    refute_problems
  end

  def test_created_at_is_not_reported
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :created_at, :datetime
    end.define_model

    refute_problems
  end

  def test_updated_at_is_not_reported
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :updated_at, :datetime
    end.define_model

    refute_problems
  end

  def test_created_on_is_not_reported
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :created_on, :datetime
    end.define_model

    refute_problems
  end

  def test_updated_on_is_not_reported
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :updated_on, :datetime
    end.define_model

    refute_problems
  end

  def test_non_datetime_column_is_not_reported
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_config_ignore_tables
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :published_at, :datetime
    end.define_model

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :datetime_without_timezone,
          ignore_tables: ["users"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_columns
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :published_at, :datetime
    end.define_model

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :datetime_without_timezone,
          ignore_columns: ["users.published_at"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_tables
    skip("#{current_adapter} doesn't support timestamp types") unless postgresql?

    Context.create_table(:users) do |t|
      t.column :published_at, :datetime
    end.define_model

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_tables, ["users"]
      end
    CONFIG

    refute_problems
  end
end
