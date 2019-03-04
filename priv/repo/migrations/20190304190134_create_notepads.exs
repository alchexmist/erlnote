defmodule Erlnote.Repo.Migrations.CreateNotepads do
  use Ecto.Migration

  def change do
    create table(:notepads) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:notepads, [:name])
    create index(:notepads, [:user_id])
  end
end
