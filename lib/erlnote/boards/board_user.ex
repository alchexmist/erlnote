defmodule Erlnote.Boards.BoardUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "boards_users" do
    belongs_to :user, Erlnote.Accounts.User, on_replace: :delete
    belongs_to :board, Erlnote.Boards.Board, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board_user, attrs) do
    board_user
    |> cast(attrs, [:board_id, :user_id])
    |> validate_required([:board_id, :user_id])
    |> unique_constraint(:board_id, name: :boards_users_board_id_user_id_index)
  end
end
