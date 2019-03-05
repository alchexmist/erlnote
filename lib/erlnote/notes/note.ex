defmodule Erlnote.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.User
  alias Erlnote.Notes.{Notepad, NoteUser, NoteTag}
  alias Erlnote.Tags.Tag

  schema "notes" do
    field :body, :string
    field :title, :string
    #field :user_id, :id
    belongs_to :user, User
    #field :notepad_id, :id
    belongs_to :notepad, Notepad
    many_to_many :users, User, join_through: NoteUser
    many_to_many :tags, Tag, join_through: NoteTag

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
  end
end
