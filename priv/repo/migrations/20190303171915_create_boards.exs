defmodule Erlnote.Repo.Migrations.CreateBoards do
  use Ecto.Migration

  def change do
    create table(:boards) do
      add :text, :text
      add :deleted, :boolean, default: false, null: false
      add :title, :string
      add :owner, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:boards, [:owner])
  end
end
