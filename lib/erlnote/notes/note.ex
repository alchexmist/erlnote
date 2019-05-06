defmodule Erlnote.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  @max_title_len 255
  @min_title_len 1

  alias Erlnote.Accounts.User
  alias Erlnote.Notes.{Notepad, NoteUser, NoteTag}
  alias Erlnote.Tags.Tag

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.
  
  schema "notes" do
    field :body, :string
    field :title, :string
    field :deleted, :boolean, default: false
    #field :user_id, :id
    belongs_to :user, User, on_replace: :delete
    #field :notepad_id, :id
    belongs_to :notepad, Notepad, on_replace: :delete
    many_to_many :users, User, join_through: NoteUser, on_replace: :delete
    many_to_many :tags, Tag, join_through: NoteTag, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def update_changeset(note, params) do
    note
    |> cast(params, [:deleted, :title, :body, :notepad_id])
    |> validate_required([:deleted, :title])
    |> validate_length(:title, min: @min_title_len, max: @max_title_len)
  end

  @doc false
  def create_changeset(note, params) do
    note
    |> cast(params, [:deleted])
    |> validate_required([:deleted])
    |> changeset(params)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> validate_length(:title, min: @min_title_len, max: @max_title_len)
  end
end
