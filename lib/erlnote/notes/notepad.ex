defmodule Erlnote.Notes.Notepad do
  use Ecto.Schema
  import Ecto.Changeset

  @max_name_len 255
  @min_name_len 1

  alias Erlnote.Accounts.User
  alias Erlnote.Notes.{Note, NotepadTag}
  alias Erlnote.Tags.Tag

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.
  
  schema "notepads" do
    field :name, :string
    #field :user_id, :id
    belongs_to :user, User
    has_many :notes, Note, on_replace: :delete
    many_to_many :tags, Tag, join_through: NotepadTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notepad, attrs) do
    notepad
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: @min_name_len, max: @max_name_len)
    |> unique_constraint(:name)
  end
end
