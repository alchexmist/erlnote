defmodule Erlnote.Repo.Migrations.FixTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :tasklist_id, references(:tasklists, on_delete: :delete_all), null: false
    end
  end
end
