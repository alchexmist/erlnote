defmodule Erlnote.Boards.BoardUser do
  use Ecto.Schema
  import Ecto.Changeset


  schema "boards_users" do
    belongs_to :users, Erlnote.Accounts.User
    belongs_to :boards, Erlnote.Boards.Board

    timestamps()
  end

  @doc false
  def changeset(board_user, attrs) do
    board_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
