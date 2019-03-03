defmodule Erlnote.Repo.Migrations.CreateBoardsUsers do
  use Ecto.Migration

  def change do
    create table(:boards_users) do
      add :boards_id, :id, null: false
      add :users_id, :id, null: false

      timestamps()
    end

  end
end
