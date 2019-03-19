defmodule Erlnote.Repo.Migrations.AddDeletedFieldToNotes do
  use Ecto.Migration

  def change do
    alter table(:notes) do
      add :deleted, :boolean, default: false, null: false
    end
  end
end
