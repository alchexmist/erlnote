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


end