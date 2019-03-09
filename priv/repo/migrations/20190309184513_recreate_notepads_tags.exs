defmodule Erlnote.Repo.Migrations.RecreateNotepadsTags do
  use Ecto.Migration

  def change do
    drop index(:notepads_tags, [:notepad_id])
    drop index(:notepads_tags, [:tag_id])
    flush()
    drop table("notepads_tags")
    flush()
    create table(:notepads_tags) do
      add :notepad_id, references(:notepads, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notepads_tags, [:notepad_id])
    create index(:notepads_tags, [:tag_id])
    create unique_index(:notepads_tags, [:notepad_id, :tag_id], name: :notepads_tags_notepad_id_tag_id_index)
  end
end
