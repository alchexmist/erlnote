defmodule ErlnoteWeb.Resolvers.Tasks do

  alias Erlnote.Tasks
  alias Erlnote.Accounts

  # mutation UpdateTaskInTasklist($taskData: UpdateTaskInput!) {
  #   task: updateTaskInTasklist(input: $taskData) {
  #     id
  #     name
  #     startDatetime
  #     endDatetime
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "taskData": {
  #     "id": "1",
  #     "tasklistId": "1",
  #     "name": "Alguna de mis tareas por hacer",
  #     "startDatetime": "2018-04-17T01:00:00Z",
  #     "endDatetime": "2018-04-17T18:00:00Z"
  #   }
  # }
  def update_task(_, %{input: params}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      %{tasklist_id: tasklist_id, id: _task_id} <- params,
      {tasklist_id, _} <- Integer.parse(tasklist_id)
      #{task_id, _} <- Integer.parse(task_id)
    ) do
      Tasks.update_task_in_tasklist(user_id, tasklist_id, Map.delete(params, :tasklist_id))
    else
      _ -> {:error, "Invalid data"}
    end
  end


  def delete_task(_, params, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      %{tasklist_id: tasklist_id, task_id: task_id} <- params,
      {tasklist_id, _} <- Integer.parse(tasklist_id),
      {task_id, _} <- Integer.parse(task_id)
    ) do
      Tasks.delete_task_from_tasklist(user_id, tasklist_id, task_id)
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation AddTaskToTasklist($taskData: AddTaskInput!) {
  #   task: addTaskToTasklist(input: $taskData) {
  #     id
  #     name
  #     startDatetime
  #     endDatetime
  #     tasklistId
  #     state
  #     priority
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "taskData": {
  #     "tasklistId": "5",
  #     "name": "Otra de mis tareas por hacer",
  #     "startDatetime": "2018-04-17T01:00:00Z",
  #     "endDatetime": "2018-04-17T18:00:00Z",
  #     "state": "INPROGRESS",
  #     "priority": "LOW"
  #   }
  # }
  def add_task(_, %{input: params}, %{context: context}) do
    with(
      %{current_user: %{id: user_id}} <- context,
      %{tasklist_id: tasklist_id} <- params,
      {tasklist_id, _} <- Integer.parse(tasklist_id)
    ) do
      Tasks.add_task_to_tasklist(user_id, tasklist_id, Map.delete(params, :tasklist_id))
    else
      _ -> {:error, "Invalid data"}
    end
  end

end