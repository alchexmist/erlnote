defmodule Erlnote.Repo.Migrations.CreateTasklists do
  use Ecto.Migration

  def change do
    create table(:tasklists) do
      add :title, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tasklists, [:user_id])
  end
end
