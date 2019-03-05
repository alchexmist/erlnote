defmodule Erlnote.Repo.Migrations.FixNotepadsTags do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE notepads_tags DROP CONSTRAINT notepads_tags_notepad_id_fkey"
    execute "ALTER TABLE notepads_tags DROP CONSTRAINT notepads_tags_tag_id_fkey"
    alter table(:notepads_tags, primary_key: false) do
      modify :notepad_id, references(:notepads, on_delete: :delete_all), null: false
      modify :tag_id, references(:tags, on_delete: :delete_all), null: false
    end
  end
end
