defmodule Erlnote.Repo.Migrations.FixTimestampsTypeCredentials do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE credentials ALTER COLUMN inserted_at DROP NOT NULL"
    execute "ALTER TABLE credentials ALTER COLUMN updated_at DROP NOT NULL"
  end
end
