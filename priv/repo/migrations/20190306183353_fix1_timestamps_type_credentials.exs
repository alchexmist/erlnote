defmodule Erlnote.Repo.Migrations.Fix1TimestampsTypeCredentials do
  use Ecto.Migration

  def change do
    alter table(:credentials) do
      remove :inserted_at
      remove :updated_at
    end
  end
end
