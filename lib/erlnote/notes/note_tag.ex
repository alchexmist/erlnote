defmodule Erlnote.Notes.NoteTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Notes.Note
  alias Erlnote.Tags.Tag

  schema "notes_tags" do
    #field :note_id, :id
    belongs_to :note, Note, on_replace: :delete
    #field :tag_id, :id
    belongs_to :tag, Tag, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note_tag, attrs) do
    note_tag
    |> cast(attrs, [:note_id, :tag_id])
    |> validate_required([:note_id, :tag_id])
    |> unique_constraint(:note_id, name: :notes_tags_note_id_tag_id_index)
  end
end
