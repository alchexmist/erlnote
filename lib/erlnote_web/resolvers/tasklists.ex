defmodule ErlnoteWeb.Resolvers.Tasklists do

  alias Erlnote.Tasks
  alias Erlnote.Accounts

  # mutation {
  #   createTasklist {
  #     id
  #     title
  #   }
  # }
  def create_tasklist(_, _, %{context: %{current_user: %{id: id}}}) do
    Tasks.create_tasklist(id)
  end

  # mutation UpdateTasklist($tasklistData: UpdateTasklistInput!) {
  #   tasklist: updateTasklist(input: $tasklistData) {
  #     id
  #     title
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "tasklistData": {
  #     "tasklistId": "5",
  #     "title": "Una de mis listas de tareas"
  #   }
  # }
  def update_tasklist(_, %{input: params}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      %{tasklist_id: tasklist_id} <- params,
      {tasklist_id, _} <- Integer.parse(tasklist_id)
    ) do
      Tasks.update_tasklist(user_id, tasklist_id, params)
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation DeleteTasklistUser($data: ID!) {
  #   deleteTasklistUser(tasklistId: $data) {
  #     id
  #     title
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": "4"
  # }
  def delete_user(_, %{tasklist_id: tasklist_id}, %{context: context}) do
    with(
      {tasklist_id, _} <- Integer.parse(tasklist_id),
      %{current_user: %{id: user_id}} <- context,
      tasklist when not is_nil(tasklist) <- Tasks.get_tasklist(tasklist_id)
    ) do
      Tasks.delete_tasklist(tasklist, user_id)
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation AddTasklistContributor($data: AddTasklistContributorFilter!){
  #   addTasklistContributor(filter: $data) {
  #     msg
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": {
  #     "type": "ID",
  #     "value": "2",
  #     "tid": "5",
  #     "canRead": true,
  #     "canWrite": true
  #   }
  # }
  def add_contributor(_, %{filter: opts}, %{context: context}) do
    r = case {opts, context} do
      {%{type: :id, value: i, tid: tid, can_read: cr, can_write: cw}, %{current_user: %{id: owner_id}}} when is_binary(i) ->
        with(
          {i, _} <- Integer.parse(i),
          {tid, _} <- Integer.parse(tid),
          user when not is_nil(user) <- Accounts.get_user_by_id(i)
        ) do
          Tasks.link_tasklist_to_user(owner_id, tid, user.id, cr, cw)
        else
          _ -> {:error, "Invalid data"}
        end
      {%{type: :username, value: u, tid: tid, can_read: cr, can_write: cw}, %{current_user: %{id: owner_id}}} when is_binary(u) ->
        with(
          {tid, _} <- Integer.parse(tid),
          user when not is_nil(user) <- Accounts.get_user_by_username(u)
        ) do
          Tasks.link_tasklist_to_user(owner_id, tid, user.id, cr, cw)
        else
          _ -> {:error, "Invalid data"}
        end
    end

    case r do
      {:ok, _} -> {:ok, %{msg: "ok"}}
      _ -> r
    end
  end

  defp delete_contributor_priv(current_user_id, tasklist_owner_id, tasklist_id, user_id) when is_integer(current_user_id) and is_integer(tasklist_owner_id) and is_integer(tasklist_id) and is_integer(user_id) do
    # user_id: ID del usuario que se quiere eliminar de la lista de tareas.
    case {current_user_id, Tasks.get_tasklist(tasklist_id)} do
      {_, nil} -> {:error, "Invalid tasklist ID"}
      {^tasklist_owner_id, t} -> Tasks.delete_tasklist(t, user_id)
      {^user_id, t} -> Tasks.delete_tasklist(t, user_id)
      _ -> {:error, "Invalid data (delete_contributor_priv) current_user_id #{current_user_id} tasklist_owner_id #{tasklist_owner_id} taslist_id #{tasklist_id} user_id #{user_id} "}
    end
  end

  def delete_contributor(_, %{filter: opts}, %{context: context}) do
    # i: ID del colaboarador que se quiere eliminar.
    # tid: ID de la lista de tareas de la que se quiere eliminar el colaborador.
    # owner_id: ID del usuario al que pertenece esta sesión.
    r = case {opts, context} do
      {%{type: :id, value: i, tid: tid}, %{current_user: %{id: owner_id}}} when is_binary(i) ->
        with(
          {i, _} <- Integer.parse(i),
          {tid, _} <- Integer.parse(tid),
          user when not is_nil(user) <- Accounts.get_user_by_id(i),
          {:ok, %{owner_id: tasklist_owner}} <- Tasks.get_access_info(owner_id, tid)
          # {:ok, %{owner_id: tasklist_owner}} <- Tasks.get_access_info(owner_id, user.id)
        ) do

          delete_contributor_priv(owner_id, tasklist_owner, tid, user.id)

        else
          _ -> {:error, "Invalid data"}
        end
      {%{type: :username, value: u, tid: tid}, %{current_user: %{id: owner_id}}} when is_binary(u) ->
        with(
          {tid, _} <- Integer.parse(tid),
          user when not is_nil(user) <- Accounts.get_user_by_username(u),
          {:ok, %{owner_id: tasklist_owner}} <- Tasks.get_access_info(owner_id, tid)
        ) do

          delete_contributor_priv(owner_id, tasklist_owner, tid, user.id)

        else
          _ -> {:error, "Invalid data"}
        end
    end

    case r do
      {:ok, _} -> {:ok, %{msg: "ok"}}
      _ -> r
    end
  end

  # mutation UpdateTasklistAccess($tasklistAccessData: UpdateTasklistAccessInput!) {
  #   updateTasklistAccess(input: $tasklistAccessData) {
  #     ... on TasklistAccessInfo {
  #       ownerId
  #       userId
  #       canRead
  #       canWrite
  #       tasklistId
  #     }
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "tasklistAccessData": {
  #     "userId": "2",
  #     "tasklistId": "5",
  #     "canRead": true,
  #     "canWrite": false
  #   }
  # }
  def update_tasklist_access(_, %{input: params}, %{context: context}) do
    with(
      %{current_user: %{id: current_user_id}} <- context,
      %{user_id: user_id, tasklist_id: tasklist_id, can_read: can_read, can_write: can_write} <- params,
      {tasklist_id, _} <- Integer.parse(tasklist_id),
      tasklist when not is_nil(tasklist) <- Tasks.get_tasklist(tasklist_id),
      {user_id, _} <- Integer.parse(user_id)
    ) do
      if tasklist.user_id == current_user_id do
        Tasks.set_can_read_from_tasklist(user_id, tasklist_id, can_read)
        Tasks.set_can_write_to_tasklist(user_id, tasklist_id, can_write)
        Tasks.get_access_info(user_id, tasklist_id)
      else
        {:error, "unauthorized"}
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation {
  #   linkTagToTasklist(tasklistId: "5", tagName: "compartido") {
  #     msg
  #   }
  # }
  def link_tag(_, %{tasklist_id: tasklist_id, tag_name: tag_name}, %{context: %{current_user: %{id: id}}}) do
    with(
      {tasklist_id, _} <- Integer.parse(tasklist_id)
    ) do
      case r = Erlnote.Tasks.link_tag_to_tasklist(tasklist_id, id, tag_name) do
        # {:ok, _} -> {:ok, %{msg: "linked"}}
        {:ok, _} -> {:ok, Erlnote.Tags.get_tag_by_name(tag_name)}
        _ -> r
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

  def remove_tag(_, %{tasklist_id: tasklist_id, tag_name: tag_name}, %{context: %{current_user: %{id: id}}}) do
    with(
      {tasklist_id, _} <- Integer.parse(tasklist_id)
    ) do
      case r = Erlnote.Tasks.remove_tag_from_tasklist(tasklist_id, id, tag_name) do
        %{remove_tag_from_tasklist: _, delete_tag: _} -> {:ok, %{msg: "deleted"}}
        :ok -> {:error, "tag name not found"}
        _ -> r
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

end