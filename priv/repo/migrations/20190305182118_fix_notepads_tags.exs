defmodule Erlnote.Repo.Migrations.FixNotepadsTags do
  use Ecto.Migration

  def change do
    drop index(:notepads_tags, [:notepad_id])
    execute "ALTER TABLE notepads_tags DROP CONSTRAINT notepads_tags_notepad_id_fkey"
    execute "ALTER TABLE notepads_tags DROP CONSTRAINT notepads_tags_tag_id_fkey"
    alter table(:notepads_tags, primary_key: false) do
      modify :notepad_id, references(:notepads, on_delete: :delete_all), null: false
      modify :tag_id, references(:tags, on_delete: :delete_all), null: false
    end
    create index(:notepads_tags, [:notepad_id])
  end
end
