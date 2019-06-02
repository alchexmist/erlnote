defmodule ErlnoteWeb.Resolvers.Notepads do

  alias Erlnote.Notes
  alias Erlnote.Accounts

    # mutation CreateNotepad {
  #   notepad: createNotepad {
  #     id
  #     name
  #     notes {
  #       id
  #       body
  #       title
  #       tags {
  #         id
  #         name
  #       }
  #     }
  #     tags {
  #       id
  #       name
  #     }
  #   }
  # }
  # Valid Authentication Token: Required (HTTP Header).
  def create_notepad(_, _, %{context: %{current_user: %{id: id}}}) do
    Notes.create_notepad(id)
  end

  # mutation UpdateNotepad {
  #   updateNotepad(notepadId: "3", newName: "Bloc de notas tres!") {
  #     id
  #     name
  #     notes {
  #       id
  #       title
  #       body
  #     }
  #     tags {
  #       id
  #       name
  #     }
  #   }
  # }
  def update_notepad(_, %{notepad_id: notepad_id, new_name: name}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      {notepad_id, _} <- Integer.parse(notepad_id),
      target_notepad when not is_nil(target_notepad) <- Erlnote.Notes.get_notepad(notepad_id)
    ) do
      Notes.update_notepad(user_id, target_notepad, %{name: name})
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation {
  #   addNoteToNotepad(noteId: "9", notepadId: "3") {
  #     id
  #     title
  #     body
  #     notepad {
  #       id
  #       name
  #     }
  #   }
  # } 
  def add_note(_, %{note_id: note_id, notepad_id: notepad_id}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      {note_id, _} <- Integer.parse(note_id),
      {notepad_id, _} <- Integer.parse(notepad_id)
    ) do
      Notes.add_note_to_notepad(user_id, note_id, notepad_id)
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation {
  #   deleteNoteFromNotepad(noteId: "9", notepadId: "3") {
  #     id
  #     title
  #     body
  #     notepad {
  #       id
  #       name
  #     }
  #   }
  # } 
  def delete_note(_, %{note_id: note_id, notepad_id: notepad_id}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      {note_id, _} <- Integer.parse(note_id),
      {notepad_id, _} <- Integer.parse(notepad_id)
    ) do
      Notes.remove_note_from_notepad(user_id, note_id, notepad_id)
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation {
  #   linkTagToNotepad(notepadId: "3", tagName: "compartido") {
  #     msg
  #   }
  # } 
  def link_tag(_, %{notepad_id: notepad_id, tag_name: tag_name}, %{context: %{current_user: %{id: id}}}) do
    with(
      {notepad_id, _} <- Integer.parse(notepad_id)
    ) do
      case r = Erlnote.Notes.link_tag_to_notepad(notepad_id, id, tag_name) do
        {:ok, _} -> {:ok, %{msg: "linked"}}
        _ -> r
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation {
  #   removeTagFromNotepad(notepadId: "3", tagName: "compartido") {
  #     msg
  #   }
  # } 
  def remove_tag(_, %{notepad_id: notepad_id, tag_name: tag_name}, %{context: %{current_user: %{id: id}}}) do
    with(
      {notepad_id, _} <- Integer.parse(notepad_id)
    ) do
      case r = Erlnote.Notes.remove_tag_from_notepad(notepad_id, id, tag_name) do
        %{remove_tag_from_notepad: _, delete_tag: _} -> {:ok, %{msg: "deleted"}}
        :ok -> {:error, "tag name not found"}
        _ -> r
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation {
  #   deleteNotepad(notepadId: "2") {
  #     id
  #     name
  #   }
  # }
  def delete_notepad(_, %{notepad_id: notepad_id}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      {notepad_id, _} <- Integer.parse(notepad_id),
      notepad when not is_nil(notepad) <- Erlnote.Notes.get_notepad(notepad_id)
    ) do
      Notes.delete_notepad(notepad, user_id)
    else
      _ -> {:error, "Invalid data"}
    end
  end

end

