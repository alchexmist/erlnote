defmodule Erlnote.Notes.NoteTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Notes.Note
  alias Erlnote.Tags.Tag

  schema "notes_tags" do
    #field :note_id, :id
    belongs_to :note, Note
    #field :tag_id, :id
    belongs_to :tag, Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note_tag, attrs) do
    note_tag
    |> cast(attrs, [])
    |> validate_required([])
  end
end
