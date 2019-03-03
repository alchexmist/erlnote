defmodule Erlnote.Repo.Migrations.FixBoardsUsers do
  use Ecto.Migration

  def change do
    alter table(:boards_users, primary_key: false) do
      modify :boards_id, references(:boards, on_delete: :delete_all), null: false
      modify :users_id, references(:users, on_delete: :delete_all), null: false
      remove :id
    end

  end
end
