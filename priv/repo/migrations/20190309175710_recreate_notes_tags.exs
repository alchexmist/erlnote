defmodule Erlnote.Repo.Migrations.RecreateNotesTags do
  use Ecto.Migration

  def change do
    drop index("notes_tags", [:note_id])
    drop index("notes_tags", [:tag_id])
    flush()
    drop table("notes_tags")
    flush()
    create table(:notes_tags) do
      add :note_id, references(:notes, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notes_tags, [:note_id])
    create index(:notes_tags, [:tag_id])
    create unique_index(:notes_tags, [:note_id, :tag_id], name: :notes_tags_note_id_tag_id_index)
  end
end
