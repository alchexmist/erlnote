defmodule ErlnoteWeb.Resolvers.Notes do

  alias Erlnote.Notes
  alias Erlnote.Accounts

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

  # mutation UpdateNoteAccess($noteAccessData: UpdateNoteAccessInput!) {
  #   updateNoteAccess(input: $noteAccessData) {
  #     ... on NoteAccessInfo {
  #       ownerId
  #       userId
  #       canRead
  #       canWrite
  #       noteId
  #     }
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "noteAccessData": {
  #     "user_id": "2",
  #     "note_id": "8",
  #     "canRead": true,
  #     "canWrite": false
  #   }
  # }
  def update_note_access(_, %{input: params}, %{context: context}) do
    with(
      %{current_user: %{id: current_user_id}} <- context,
      %{user_id: user_id, note_id: note_id, can_read: can_read, can_write: can_write} <- params,
      {note_id, _} <- Integer.parse(note_id),
      note when not is_nil(note) <- Notes.get_note(note_id),
      {user_id, _} <- Integer.parse(user_id)
    ) do
      if note.user_id == current_user_id do
        Notes.set_can_read_from_note(user_id, note_id, can_read)
        Notes.set_can_write_to_note(user_id, note_id, can_write)
        Notes.get_access_info(user_id, note_id)
      else
        {:error, "unauthorized"}
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation AddNoteContributor($data: AddNoteContributorFilter!){
  #   addNoteContributor(filter: $data) {
  #     msg
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": {
  #     "type": "ID",
  #     "value": "2",
  #     "nid": "8",
  #     "canRead": "true",
  #     "canWrite": "true"
  #   }
  # }
  # RESULT
  # {
  #   "data": {
  #     "addNoteContributor": {
  #       "msg": "ok"
  #     }
  #   }
  # }
  def add_contributor(_, %{filter: opts}, %{context: context}) do
    r = case {opts, context} do
      {%{type: :id, value: i, nid: nid, can_read: cr, can_write: cw}, %{current_user: %{id: owner_id}}} when is_binary(i) ->
        with(
          {i, _} <- Integer.parse(i),
          {nid, _} <- Integer.parse(nid),
          user when not is_nil(user) <- Accounts.get_user_by_id(i)
        ) do
          Notes.link_note_to_user(owner_id, nid, user.id, cr, cw)
        else
          _ -> {:error, "Invalid data"}
        end
      {%{type: :username, value: u, nid: nid, can_read: cr, can_write: cw}, %{current_user: %{id: owner_id}}} when is_binary(u) ->
        with(
          {nid, _} <- Integer.parse(nid),
          user when not is_nil(user) <- Accounts.get_user_by_username(u)
        ) do
          Notes.link_note_to_user(owner_id, nid, user.id, cr, cw)
        else
          _ -> {:error, "Invalid data"}
        end
    end

    case r do
      {:ok, _} -> {:ok, %{msg: "ok"}}
      _ -> r
    end
  end

  # mutation DeleteNoteUser($data: ID!) {
  #   deleteNoteUser(noteId: $data) {
  #     id
  #     title
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": "7"
  # }
  # RESPONSE
  # {
  #   "data": {
  #     "deleteNoteUser": {
  #       "title": "note-8fed75fe-a283-4aca-bc28-29f5c393aa77",
  #       "id": "7"
  #     }
  #   }
  # }
  def delete_user(_, %{note_id: note_id}, %{context: context}) do
    with(
      {note_id, _} <- Integer.parse(note_id),
      %{current_user: %{id: user_id}} <- context,
      note when not is_nil(note) <- Notes.get_note(note_id)
    ) do
      Notes.delete_note(note, user_id)
    else
      _ -> {:error, "Invalid data"}
    end
  end

  def link_tag(_, %{note_id: note_id, tag_name: tag_name}, %{context: %{current_user: %{id: id}}}) do
    with(
      {note_id, _} <- Integer.parse(note_id)
    ) do
      case r = Erlnote.Notes.link_tag_to_note(note_id, id, tag_name) do
        {:ok, _} -> {:ok, %{msg: "linked"}}
        _ -> r
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

end