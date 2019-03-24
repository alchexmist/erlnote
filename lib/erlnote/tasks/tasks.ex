defmodule Erlnote.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Tasks.{Tasklist, TasklistUser, TasklistTag, Task}
  alias Erlnote.Accounts
  alias Erlnote.Tags
  alias Erlnote.Tags.Tag

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

  @doc false
  defp set_tasklist_user_permissions(user_id, tasklist_id, pname, pvalue) do
    case Repo.one(
        from r in TasklistUser,
        where: r.user_id == ^user_id,
        where: r.tasklist_id == ^tasklist_id
      ) do
        nil -> {:error, "User-Tasklist assoc: not found."}
        x ->
          case pname do
            :can_read ->
              x
              #|> Repo.preload(:tasklist)
              #|> Repo.preload(:user)
              |> TasklistUser.update_read_permission_changeset(%{tasklist_id: tasklist_id, user_id: user_id, can_read: pvalue})
              |> Repo.update()
            :can_write ->
              x
              #|> Repo.preload(:tasklist)
              #|> Repo.preload(:user)
              |> TasklistUser.update_write_permission_changeset(%{tasklist_id: tasklist_id, user_id: user_id, can_write: pvalue})
              |> Repo.update()
          end
      end
  end

  def set_can_read_from_tasklist(user_id, tasklist_id, can_read)
    when is_integer(user_id) and is_integer(tasklist_id) and is_boolean(can_read) do
      set_tasklist_user_permissions(user_id, tasklist_id, :can_read, can_read)
  end

  def set_can_write_to_tasklist(user_id, tasklist_id, can_write)
    when is_integer(user_id) and is_integer(tasklist_id) and is_boolean(can_write) do
      set_tasklist_user_permissions(user_id, tasklist_id, :can_write, can_write)
  end

  defp can_read_or_write?(user_id, tasklist_id) do
    case tl = (get_tasklist(tasklist_id) |> Repo.preload(:user)) do
      nil -> {false, false}
      _ ->
        cond do
          user_id == tl.user.id -> {true, true}
          true ->
            record = Repo.one(from r in TasklistUser, where: r.tasklist_id == ^tl.id, where: r.user_id == ^user_id)
            not_is_nil_record = not is_nil(record)
            {
              not_is_nil_record and record.can_read == true,
              not_is_nil_record and record.can_write == true
            }
        end
    end
  end

  def can_write?(user_id, tasklist_id) do
    Kernel.elem(can_read_or_write?(user_id, tasklist_id), 1)
  end

  def can_read?(user_id, tasklist_id) do
    Kernel.elem(can_read_or_write?(user_id, tasklist_id), 0)
  end

  def list_tasks_from_tasklist(tasklist_id) when is_integer(tasklist_id) do
    case tl = get_tasklist(tasklist_id) do
      nil -> {:error, "Tasklist ID not found."}
      _ ->
        (tl |> Repo.preload(:tasks)).tasks
    end
  end

  def get_task_from_tasklist(user_id, tasklist_id, task_id) do
    if can_read?(user_id, tasklist_id) do
      tl = (get_tasklist(tasklist_id) |> Repo.preload(:tasks))
      case q = ((from r in assoc(tl, :tasks), where: r.id == ^task_id) |> Repo.one) do
        nil -> {:error, "Task not found."}
        _ -> q
      end
    else
      {:error, "Permission denied (read)."}
    end
  end

  # changes: Es un map que debe incluir una clave con el id de la tarea.
  # Tasks.update_task_in_tasklist(1, 5, %{id: 1, name: "Tarea número 1"})
  def update_task_in_tasklist(user_id, tasklist_id, changes) do
    if can_write?(user_id, tasklist_id) and Map.has_key?(changes, :id) do
      case t = get_task_from_tasklist(user_id, tasklist_id, changes.id) do
        {:error, _ } -> t
        _ -> t |> Task.update_changeset(changes) |> Repo.update
      end
    else
      {:error, "Permission denied (write) or Task ID not found (changes map)."}
    end  
  end

  def delete_task_from_tasklist(user_id, tasklist_id, task_id) do
    if can_write?(user_id, tasklist_id) do
      case t = get_task_from_tasklist(user_id, tasklist_id, task_id) do
        {:error, _ } -> t
        _ -> t |> Repo.delete
      end
    else
      {:error, "Permission denied (write)."}
    end
  end

  def add_task_to_tasklist(user_id, tasklist_id, task)
    when is_integer(user_id) and is_integer(tasklist_id) and is_map(task) do
      case can_write?(user_id, tasklist_id) do
        true ->
          #Crear la tarea con el changeset desde el map task, usando build_assoc.
          #Insertar la tarea en la lista de tareas.
          get_tasklist(tasklist_id)
          |> build_assoc(:tasks)
          |> Task.create_changeset(task)
          |> Repo.insert()
        _ -> {:error, "Permission denied."}
      end

  end

  def get_tags_from_tasklist(tasklist_id) when is_integer(tasklist_id) do
    tl = (get_tasklist(tasklist_id) |> Repo.preload(:tags))
    case tl do
      nil -> []
      _ -> tl.tags
    end
  end

  def link_tag_to_tasklist(tasklist_id, user_id, tag_name)
    when is_integer(tasklist_id) and is_integer(user_id) and is_binary(tag_name) do
      
    user = Accounts.get_user_by_id(user_id)
    tasklist = (get_tasklist(tasklist_id) |> Repo.preload(:tags))
    cond do
      is_nil(user) or is_nil(tasklist) or not can_write?(user_id, tasklist_id) ->
        {:error, "user ID not found or tasklist ID not found or disabled write permission."}
      #(tasklist |> Repo.preload(:user)).user.id == user_id -> {:ok, "linked"}
      true ->
        Process.put(:target_tag, Repo.one(from t in tasklist.tags, where: t.name == ^tag_name))
        contains_tag? = not is_nil(Process.get(:target_tag))
        if not contains_tag? do
          if Tags.get_tag_by_name(tag_name) == nil do
            {_, target_tag} = Tags.create_tag(%{name: tag_name})
            Process.put(:target_tag, target_tag)
          end
          case target_tag = Process.get(:target_tag) do
            %Tag{} ->
              Process.put(:result,
                          Repo.insert(
                            TasklistTag.changeset(%TasklistTag{}, %{tasklist_id: tasklist.id, tag_id: target_tag.id})
                          )
              )
              # Return {:ok, _} o {:error, changeset}
              _ -> Process.put(:result, {:error, "Unlinked tag - tasklist."})
          end
        else
          Process.put(:result, {:ok, "linked"})
        end
        Process.delete(:target_tag)
        Process.delete(:result)
    end
  end

end
