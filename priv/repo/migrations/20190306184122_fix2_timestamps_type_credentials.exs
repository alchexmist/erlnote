defmodule Erlnote.Repo.Migrations.Fix2TimestampsTypeCredentials do
  use Ecto.Migration
  
  def change do
    alter table(:credentials) do
      timestamps(type: :utc_datetime)
    end
  end
end
