defmodule ErlnoteWeb.Schema.NotepadsTypes do
  use Absinthe.Schema.Notation

  object :notepad do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :notes, list_of(:note) do
      resolve fn notepad, _, _ ->
        {:ok, Erlnote.Notes.get_notes_in_notepad(notepad.id)}
      end
    end
    field :tags, list_of(:tag) do
      resolve fn notepad, _, _ ->
        {:ok, Erlnote.Notes.get_tags_from_notepad(notepad.id)}
      end
    end
  end

end