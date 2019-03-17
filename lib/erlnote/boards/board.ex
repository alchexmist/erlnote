defmodule Erlnote.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset

  @max_title_len 255
  @min_title_len 1

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
  def update_changeset(board, params) do
    board
    |> cast(params, [:deleted, :text, :title])
    |> validate_inclusion(:deleted, [true, false])
    |> validate_length(:title, min: @min_title_len, max: @max_title_len)
  end

  @doc false
  def create_changeset(board, params) do
    board
    |> cast(params, [:deleted])
    |> validate_required([:deleted])
    |> validate_inclusion(:deleted, [true, false])
    |> changeset(params)
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:text, :title])
    |> validate_required([:title])
    |> validate_length(:title, min: @min_title_len, max: @max_title_len)
  end
end
