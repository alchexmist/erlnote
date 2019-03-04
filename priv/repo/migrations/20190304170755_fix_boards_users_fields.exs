defmodule Erlnote.Repo.Migrations.FixBoardsUsersFields do
  use Ecto.Migration

  def change do
    alter table(:boards_users, primary_key: false) do
      remove :boards_id, references(:boards, on_delete: :delete_all), null: false
      remove :users_id, references(:users, on_delete: :delete_all), null: false
      add :board_id, references(:boards, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      
      flush()

    end

  end
end
