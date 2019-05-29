defmodule ErlnoteWeb.Resolvers.Notes do

  alias Erlnote.Notes

  # mutation CreateNote {
  #   note: createNote {
  #     id
  #     title
  #     body
  #   }
  # }
  # {
  #   "data": {
  #     "note": {
  #       "title": "note-5c3c8462-45c7-43d9-9c04-090f894f8981",
  #       "id": "5"
  #       "body": null
  #     }
  #   }
  # }
  # Valid Authentication Token: Required (HTTP Header).
  def create_note(_, _, %{context: %{current_user: %{id: id}}}) do
    Notes.create_note(id)
  end

  # mutation UpdateNote($noteData: UpdateNoteInput!) {
  #   note: updateNote(input: $noteData) {
  #     id
  #     body
  #     title
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "noteData": {
  #     "id": "1",
  #     "body": "Contenido de mi notita",
  #     "title": "Una de mis notitas"
  #   }
  # }
  def update_note(_, %{input: params}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      %{id: n_id} <- params,
      {note_id, _} <- Integer.parse(n_id)
    ) do
      Notes.update_note(user_id, note_id, params)
    else
      _ -> {:error, "Invalid data"}
    end
  end


end