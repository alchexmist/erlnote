defmodule Erlnote.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset


  schema "boards" do
    field :deleted, :boolean, default: false
    field :text, :string
    field :title, :string
    #field :owner, :id
    belongs_to :user, Erlnote.Accounts.User, foreign_key: :owner
    many_to_many :users, Erlnote.Accounts.User, join_through: Erlnote.Boards.BoardUser

    timestamps()
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:text, :deleted, :title])
    |> validate_required([:text, :deleted, :title])
  end
end
