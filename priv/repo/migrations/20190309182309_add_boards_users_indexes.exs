defmodule Erlnote.Repo.Migrations.AddBoardsUsersIndexes do
  use Ecto.Migration

  def change do
    create index(:boards_users, [:board_id])
    create index(:boards_users, [:user_id])
  end
end
