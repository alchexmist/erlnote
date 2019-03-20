defmodule Erlnote.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

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
    many_to_many :users, User, join_through: NoteUser
    many_to_many :tags, Tag, join_through: NoteTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
  end
end
