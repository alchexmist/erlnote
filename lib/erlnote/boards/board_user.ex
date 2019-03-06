defmodule Erlnote.Boards.BoardUser do
  use Ecto.Schema
  import Ecto.Changeset


  schema "boards_users" do
    belongs_to :user, Erlnote.Accounts.User
    belongs_to :board, Erlnote.Boards.Board

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board_user, attrs) do
    board_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
