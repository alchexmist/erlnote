defmodule Erlnote.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Tasks.{Tasklist, TasklistUser, TasklistTag, Task}
  alias Erlnote.Accounts.User
  alias Erlnote.Accounts

  def create_tasklist(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> {:error, "User ID not found."}
      _ ->
        build_assoc(user, :owner_tasklists)
        |> Tasklist.create_changeset(%{title: "tasklist-" <> Ecto.UUID.generate, deleted: false})
        |> Repo.insert()
    end
  end

  def list_is_owner_tasklists(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> (user |> Repo.preload(:owner_tasklists)).owner_tasklists
    end
  end

  def get_tasklist(id) when is_integer(id), do: Repo.get(Tasklist, id)

  def update_tasklist(%Tasklist{} = tasklist, attrs) do
    tasklist
    |> Tasklist.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_tasklist(%Tasklist{} = tasklist, user_id) when is_integer(user_id) do
    case tasklist_users = Repo.preload(tasklist, :users) do
      nil -> {:error, %Ecto.Changeset{}}
      _ ->
        tasklist = (tasklist |> Repo.preload(:user))
        cond do
          tasklist_users.users == [] and user_id == tasklist.user_id ->
            Repo.delete(tasklist)
          user_id == tasklist.user_id ->
            update_tasklist(tasklist, %{deleted: true})
          true ->
            from(r in TasklistUser, where: r.user_id == ^user_id, where: r.tasklist_id == ^tasklist.id) |> Repo.delete_all
            if Repo.all(from(u in TasklistUser, where: u.tasklist_id == ^tasklist.id)) == [] and tasklist.deleted do
              Repo.delete(tasklist)
            end
        end
    end
  end

  # Para unlink usar la función delete_tasklist.
  def link_tasklist_to_user(tasklist_id, user_id, can_read, can_write) when is_integer(tasklist_id) and is_integer(user_id) do
    user = Accounts.get_user_by_id(user_id)
    tasklist = get_tasklist(tasklist_id)
    cond do
      is_nil(user) or is_nil(tasklist) -> {:error, "user ID or tasklist ID not found."}
      (tasklist |> Repo.preload(:user)).user.id == user_id -> {:ok, "linked"}
      true ->
        Repo.insert(
          TasklistUser.changeset(%TasklistUser{}, %{tasklist_id: tasklist.id, user_id: user.id, can_read: can_read, can_write: can_write})
        )
        # Return {:ok, _} o {:error, changeset}
    end
  end

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{source: %Task{}}

  """
  def change_task(%Task{} = task) do
    Task.changeset(task, %{})
  end
end
