defmodule Erlnote.Notes.NoteUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.User
  alias Erlnote.Notes.Note

  schema "notes_users" do
    field :can_read, :boolean, default: true
    field :can_write, :boolean, default: true
    #field :note_id, :id
    belongs_to :note, Note, on_replace: :delete
    #field :user_id, :id
    belongs_to :user, User, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def update_read_permission_changeset(note_user, attrs) do
    note_user
    |> cast(attrs, [:can_read, :note_id, :user_id])
    |> validate_required([:can_read, :note_id, :user_id])
    |> unique_constraint(:note_id, name: :notes_users_note_id_user_id_index)
  end

  def update_write_permission_changeset(note_user, attrs) do
    note_user
    |> cast(attrs, [:can_write, :note_id, :user_id])
    |> validate_required([:can_write, :note_id, :user_id])
    |> unique_constraint(:note_id, name: :notes_users_note_id_user_id_index)
  end

  @doc false
  def changeset(note_user, attrs) do
    note_user
    |> cast(attrs, [:can_read, :can_write, :note_id, :user_id])
    |> validate_required([:can_read, :can_write, :note_id, :user_id])
    |> unique_constraint(:note_id, name: :notes_users_note_id_user_id_index)
  end
end
