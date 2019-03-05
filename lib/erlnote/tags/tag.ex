defmodule Erlnote.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Notes.{Notepad, NotepadTag}


  schema "tags" do
    field :name, :string
    many_to_many :notepads, Notepad, join_through: NotepadTag


    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> unique_constraint(:name)
  end
end
