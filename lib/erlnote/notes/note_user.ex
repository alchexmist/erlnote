defmodule Erlnote.Notes.NoteUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.User
  alias Erlnote.Notes.Note

  schema "notes_users" do
    #field :note_id, :id
    belongs_to :note, Note
    #field :user_id, :id
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note_user, attrs) do
    note_user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
