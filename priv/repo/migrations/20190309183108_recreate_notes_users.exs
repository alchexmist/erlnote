defmodule Erlnote.Repo.Migrations.RecreateNotesUsers do
  use Ecto.Migration

  def change do
    drop index(:notes_users, [:note_id])
    drop index(:notes_users, [:user_id])
    flush()
    drop table("notes_users")
    flush()
    create table(:notes_users) do
      add :note_id, references(:notes, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :can_read, :boolean, default: true
      add :can_write, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:notes_users, [:note_id])
    create index(:notes_users, [:user_id])
    create unique_index(:notes_users, [:note_id, :user_id], name: :notes_users_note_id_user_id_index)
  end
end
