defmodule Erlnote.Repo.Migrations.CreateNotesTags do
  use Ecto.Migration

  def change do
    create table(:notes_tags, primary_key: false) do
      add :note_id, references(:notes, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notes_tags, [:note_id])
    create index(:notes_tags, [:tag_id])
  end
end
