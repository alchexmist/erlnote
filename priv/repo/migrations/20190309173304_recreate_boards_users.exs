defmodule Erlnote.Repo.Migrations.RecreateBoardsUsers do
  use Ecto.Migration

  def change do
    drop table("boards_users")
    flush()
    create table(:boards_users) do
      add :board_id, references(:boards, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:boards_users, [:board_id, :user_id], name: :boards_users_board_id_user_id_index)
  end
end
