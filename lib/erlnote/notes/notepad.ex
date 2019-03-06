defmodule Erlnote.Notes.Notepad do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.User
  alias Erlnote.Notes.{Note, NotepadTag}
  alias Erlnote.Tags.Tag


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
    |> unique_constraint(:name)
  end
end
