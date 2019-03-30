defmodule Erlnote.Notes.NotepadTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Notes.Notepad
  alias Erlnote.Tags.Tag

  schema "notepads_tags" do
    #field :notepad_id, :id
    belongs_to :notepad, Notepad, on_replace: :delete
    #field :tag_id, :id
    belongs_to :tag, Tag, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notepad_tag, attrs) do
    notepad_tag
    |> cast(attrs, [:notepad_id, :tag_id])
    |> validate_required([:notepad_id, :tag_id])
    |> unique_constraint(:notepad_id, name: :notepads_tags_notepad_id_tag_id_index)
  end
end
