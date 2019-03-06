defmodule Erlnote.Repo.Migrations.FixTimestampsTypeUsers do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE users ALTER COLUMN inserted_at DROP NOT NULL"
    execute "ALTER TABLE users ALTER COLUMN updated_at DROP NOT NULL"
    alter table(:users) do
      remove :inserted_at
      remove :updated_at
      flush()
      timestamps(type: :utc_datetime)
    end
  end
end
