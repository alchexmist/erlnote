defmodule Erlnote.Repo.Migrations.FixTimestampsTypeAll do
  use Ecto.Migration

  def change do
    # execute "ALTER TABLE boards_users ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE boards_users ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:boards_users) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE boards ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE boards ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:boards) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE notes_tags ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE notes_tags ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:notes_tags) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE notes_users ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE notes_users ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:notes_users) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE notes ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE notes ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:notes) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE notepads_tags ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE notepads_tags ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:notepads_tags) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE notepads ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE notepads ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:notepads) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end

    # execute "ALTER TABLE tags ALTER COLUMN inserted_at DROP NOT NULL"
    # execute "ALTER TABLE tags ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:tags) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end
  end
end
