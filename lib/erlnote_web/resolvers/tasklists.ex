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

end