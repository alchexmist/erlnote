defmodule Erlnote.Repo.Migrations.AddPkBoardsUsers do
  use Ecto.Migration

  def change do
    alter table(:boards_users) do
      add :id, :id, primary_key: true
    end
  end
end
