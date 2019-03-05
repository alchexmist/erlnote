defmodule Erlnote.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.Credential
  alias Erlnote.Boards.{Board, BoardUser}
  alias Erlnote.Notes.{Notepad, Note, NoteUser}

  schema "users" do
    field :name, :string
    field :username, :string
    has_one :credential, Credential
    # Los hijos los añadimos con build_assoc.
    has_many :owner_boards, Board, foreign_key: :owner, on_replace: :delete
    has_many :notepads, Notepad, on_replace: :delete
    has_many :notes, Note, on_replace: :delete
    many_to_many :boards, Board, join_through: BoardUser
    many_to_many :notes_access, Note, join_through: NoteUser

    timestamps()
  end

  @doc false
  def registration_changeset(user, params) do
    user
    |> changeset(params)
    |> cast_assoc(:credential, with: &Credential.changeset/2, required: true)
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
