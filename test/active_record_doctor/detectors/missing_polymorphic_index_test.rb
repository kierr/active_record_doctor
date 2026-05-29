# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingPolymorphicIndexTest < Minitest::Test
  def test_polymorphic_without_index
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :commentable_type
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    assert_problems(<<~OUTPUT)
      add a composite index on users(commentable_type, commentable_id) - polymorphic association Context::User.commentable is not indexed
    OUTPUT
  end

  def test_polymorphic_with_composite_index
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :commentable_type
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    Context.execute(<<~SQL)
      CREATE INDEX index_users_on_commentable_type_and_id ON users (commentable_type, commentable_id)
    SQL

    refute_problems
  end

  def test_polymorphic_with_index_where_type_is_not_first_column
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :commentable_type
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    Context.execute(<<~SQL)
      CREATE INDEX index_users_on_id_and_type ON users (commentable_id, commentable_type)
    SQL

    assert_problems(<<~OUTPUT)
      add a composite index on users(commentable_type, commentable_id) - polymorphic association Context::User.commentable is not indexed
    OUTPUT
  end

  def test_non_polymorphic_belongs_to_is_not_reported
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:companies)
    Context.create_table(:users) do |t|
      t.references :company, foreign_key: false
    end.define_model do
      belongs_to :company
    end

    refute_problems
  end

  def test_model_without_polymorphic_associations_is_not_reported
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :name
    end.define_model

    refute_problems
  end

  def test_model_without_table_is_not_reported
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.define_model(:Comment) do
      belongs_to :commentable, polymorphic: true
    end

    refute_problems
  end

  def test_config_ignore_models
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :commentable_type
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_polymorphic_index,
          ignore_models: ["Context::User"]
      end
    CONFIG

    refute_problems
  end

  def test_config_ignore_associations
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :commentable_type
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.detector :missing_polymorphic_index,
          ignore_associations: ["Context::User.commentable"]
      end
    CONFIG

    refute_problems
  end

  def test_global_ignore_models
    skip("#{current_adapter} doesn't support check constraints") unless postgresql?

    Context.create_table(:users) do |t|
      t.string :commentable_type
      t.integer :commentable_id
    end.define_model do
      belongs_to :commentable, polymorphic: true
    end

    config_file(<<~CONFIG)
      ActiveRecordDoctor.configure do |config|
        config.global :ignore_models, ["Context::User"]
      end
    CONFIG

    refute_problems
  end
end
