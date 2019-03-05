defmodule Erlnote.Repo.Migrations.CreateNotepadsTags do
  use Ecto.Migration

  def change do
    create table(:notepads_tags, primary_key: false) do
      add :notepad_id, references(:notepads, on_delete: :delete_all)
      add :tag_id, references(:tags, on_delete: :delete_all)

      timestamps()
    end

    create index(:notepads_tags, [:notepad_id])
    create index(:notepads_tags, [:tag_id])
  end
end
