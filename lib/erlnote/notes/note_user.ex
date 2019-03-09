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
    |> cast(attrs, [:note_id, :user_id])
    |> validate_required([:note_id, :user_id])
    |> unique_constraint(:note_id, name: :notes_users_note_id_user_id_index)
  end
end
