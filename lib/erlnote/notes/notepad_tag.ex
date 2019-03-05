defmodule Erlnote.Notes.NotepadTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Notes.Notepad
  alias Erlnote.Tags.Tag

  schema "notepads_tags" do
    #field :notepad_id, :id
    belongs_to :notepad, Notepad
    #field :tag_id, :id
    belongs_to :tag, Tag

    timestamps()
  end

  @doc false
  def changeset(notepad_tag, attrs) do
    notepad_tag
    |> cast(attrs, [])
    |> validate_required([])
  end
end
