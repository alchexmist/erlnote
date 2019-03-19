defmodule Erlnote.Repo.Migrations.AddDeletedFieldToTasklists do
  use Ecto.Migration

  def change do
    alter table(:tasklists) do
      add :deleted, :boolean, default: false, null: false
    end
  end
end
