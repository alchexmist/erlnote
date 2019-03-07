defmodule Erlnote.Repo.Migrations.CreateTasklistsTags do
  use Ecto.Migration

  def change do
    create table(:tasklists_tags) do
      add :tasklist_id, references(:tasklists, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tasklists_tags, [:tasklist_id])
    create index(:tasklists_tags, [:tag_id])
  end
end
