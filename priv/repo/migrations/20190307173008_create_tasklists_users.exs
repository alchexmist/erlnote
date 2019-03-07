defmodule Erlnote.Repo.Migrations.CreateTasklistsUsers do
  use Ecto.Migration

  def change do
    create table(:tasklists_users) do
      add :can_read, :boolean, default: true, null: false
      add :can_write, :boolean, default: true, null: false
      add :tasklist_id, references(:tasklists, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tasklists_users, [:tasklist_id])
    create index(:tasklists_users, [:user_id])
  end
end
