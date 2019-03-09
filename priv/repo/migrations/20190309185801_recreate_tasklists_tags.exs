defmodule Erlnote.Repo.Migrations.RecreateTasklistsTags do
  use Ecto.Migration

  def change do
    drop index(:tasklists_tags, [:tasklist_id])
    drop index(:tasklists_tags, [:tag_id])
    flush()
    drop table("tasklists_tags")
    flush()
    create table(:tasklists_tags) do
      add :tasklist_id, references(:tasklists, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tasklists_tags, [:tasklist_id])
    create index(:tasklists_tags, [:tag_id])
    create unique_index(:tasklists_tags, [:tasklist_id, :tag_id], name: :tasklists_tags_tasklist_id_tag_id_index)
  end
end
