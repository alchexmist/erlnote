defmodule Erlnote.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :title, :string
      add :body, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :notepad_id, references(:notepads, on_delete: :nilify_all)

      timestamps()
    end

    create index(:notes, [:user_id])
    create index(:notes, [:notepad_id])
  end
end
