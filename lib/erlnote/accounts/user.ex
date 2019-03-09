defmodule Erlnote.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.Credential
  alias Erlnote.Boards.{Board, BoardUser}
  alias Erlnote.Notes.{Notepad, Note, NoteUser}
  alias Erlnote.Tasks.{Tasklist, TasklistUser}

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.

  schema "users" do
    field :name, :string
    field :username, :string
    has_many :credentials, Credential, on_replace: :delete
    # Los hijos los añadimos con build_assoc.
    has_many :owner_boards, Board, foreign_key: :owner, on_replace: :delete
    has_many :notepads, Notepad, on_replace: :delete
    has_many :notes, Note, on_replace: :delete
    has_many :owner_tasklists, Tasklist, on_replace: :delete
    many_to_many :boards, Board, join_through: BoardUser
    many_to_many :notes_access, Note, join_through: NoteUser
    many_to_many :tasklists, Tasklist, join_through: TasklistUser

    timestamps(type: :utc_datetime)
  end

  @doc false
  def registration_changeset(user, params) do
    user
    |> changeset(params)
    |> cast_assoc(:credentials, with: &Credential.changeset/2, required: true)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:username, min: 1, max: 50)
    |> unique_constraint(:username)
  end
end
