defmodule Erlnote.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.

  schema "boards" do
    field :deleted, :boolean, default: false
    field :text, :string
    field :title, :string
    #field :owner, :id
    belongs_to :user, Erlnote.Accounts.User, foreign_key: :owner
    many_to_many :users, Erlnote.Accounts.User, join_through: Erlnote.Boards.BoardUser

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:text, :deleted, :title])
    |> validate_required([:text, :deleted, :title])
  end
end
