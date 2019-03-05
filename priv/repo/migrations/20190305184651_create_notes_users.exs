defmodule Erlnote.Repo.Migrations.CreateNotesUsers do
  use Ecto.Migration

  def change do
    create table(:notes_users, primary_key: false) do
      add :note_id, references(:notes, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:notes_users, [:note_id])
    create index(:notes_users, [:user_id])
  end
end
