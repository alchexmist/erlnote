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


end