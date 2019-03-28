defmodule Erlnote.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Tasks.{Tasklist, TasklistUser, TasklistTag, Task}
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User
  alias Erlnote.Tags
  alias Erlnote.Tags.Tag

  @doc """
  Creates a tasklist. List owner == User ID.

  ## Examples

      iex> create_tasklist(1)
      {:ok, %Tasklist{}}

      iex> create_tasklist(-1)
      {:error, %Ecto.Changeset{}}

  """
  def create_tasklist(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil ->
        {
          :error,
          change(%Tasklist{}, %{user: %User{id: user_id}})
          |> add_error(:user, user_id |> Integer.to_string, additional: "User ID not found.")
        }
      _ ->
        build_assoc(user, :owner_tasklists)
        |> Tasklist.create_changeset(%{title: "tasklist-" <> Ecto.UUID.generate, deleted: false})
        |> Repo.insert()
    end
  end

  @doc """
  Returns the list of tasklists. Tasklist owner == User ID.

  ## Examples

      iex> list_is_owner_tasklists(1)
      [%Tasklist{}]

      iex> list_is_owner_tasklists(-1)
      []

  """
  def list_is_owner_tasklists(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> (user |> Repo.preload(:owner_tasklists)).owner_tasklists
      # _ -> (from u in assoc(user, :owner_tasklists)) |> Repo.all
    end
  end

  @doc """
  Gets a single tasklist.

  Returns nil if the tasklist does not exist.

  ## Examples

      iex> get_tasklist(1)
      %Tasklist{}

      iex> get_tasklist(-1)
      nil

  """
  def get_tasklist(id) when is_integer(id), do: Repo.get(Tasklist, id)

  @doc """
  Updates a tasklist.

  ## Examples

      iex> update_tasklist(tasklist, %{field: new_value})
      {:ok, %Tasklist{}}

      iex> update_tasklist(tasklist, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tasklist(%Tasklist{} = tasklist, attrs) do
    tasklist
    |> Tasklist.update_changeset(attrs)
    |> Repo.update()
  end

  defp get_tasklist_tags(%Tasklist{} = tl) do
    (Repo.preload(tl, :tags)).tags
    |> Enum.map(fn x -> x.id end)
  end

  defp delete_tasklist_tags(%Tasklist{} = tl, tag_id_list) do
    (from tt in TasklistTag, where: tt.tag_id in ^tag_id_list, where: tt.tasklist_id == ^tl.id)
    |> Repo.delete_all
    Enum.map(tag_id_list, fn x -> Tags.delete_tag(Tags.get_tag(x)) end)
  end

  defp delete_tasklist(%Tasklist{} = tl) do
    tag_list = get_tasklist_tags(tl)
    r = Repo.delete(tl)
    delete_tasklist_tags(tl, tag_list)
    r
  end

  @doc """
  Deletes a Tasklist in the name of the user with ID == user_id.

  ## Examples

      iex> delete_tasklist(tasklist, user_id)
      {:ok, %Tasklist{}}

      iex> delete_board(board, user_id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tasklist(%Tasklist{} = tasklist, user_id) when is_integer(user_id) do
        tasklist = (tasklist |> Repo.preload([:user, :users]))
        cond do
          tasklist.users == [] and user_id == tasklist.user_id -> # Tasklist without users (Owner)
            delete_tasklist(tasklist)
          user_id == tasklist.user_id -> # Tasklist with users (Owner)
            update_tasklist(tasklist, %{deleted: true})
          true ->
            from(r in TasklistUser, where: r.user_id == ^user_id, where: r.tasklist_id == ^tasklist.id) |> Repo.delete_all
            if Repo.all(from(u in TasklistUser, where: u.tasklist_id == ^tasklist.id)) == [] and tasklist.deleted do
              delete_tasklist(tasklist)
            end
        end
  end

  # def delete_tasklist(%Tasklist{} = tasklist, user_id) when is_integer(user_id) do
  #   case tasklist_users = Repo.preload(tasklist, :users) do
  #     nil -> {:error, %Ecto.Changeset{}}
  #     _ ->
  #       tasklist = (tasklist |> Repo.preload(:user))
  #       cond do
  #         tasklist_users.users == [] and user_id == tasklist.user_id ->
  #           Repo.delete(tasklist)
  #         user_id == tasklist.user_id ->
  #           update_tasklist(tasklist, %{deleted: true})
  #         true ->
  #           from(r in TasklistUser, where: r.user_id == ^user_id, where: r.tasklist_id == ^tasklist.id) |> Repo.delete_all
  #           if Repo.all(from(u in TasklistUser, where: u.tasklist_id == ^tasklist.id)) == [] and tasklist.deleted do
  #             Repo.delete(tasklist)
  #           end
  #       end
  #   end
  # end

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
    Repo.all(from r in (get_tasklist(tasklist_id) |> Repo.preload(:tags) |> assoc(:tags)))
  end

  def link_tag_to_tasklist(tasklist_id, user_id, tag_name)
    when is_integer(tasklist_id) and is_integer(user_id) and is_binary(tag_name) do

    with(
      tasklist when not is_nil(tasklist) <- (get_tasklist(tasklist_id) |> Repo.preload(:tags)),
      true <- can_write?(user_id, tasklist_id)
    ) do
      
      cond do
        is_nil(Repo.one(from t in assoc(tasklist, :tags), where: t.name == ^tag_name)) ->
          case {_, target_tag} = Tags.create_tag(tag_name) do
            {:ok, %Tag{}} ->
              Repo.insert(
                          TasklistTag.changeset(%TasklistTag{}, %{tasklist_id: tasklist.id, tag_id: target_tag.id})
              )
              # Return {:ok, _} o {:error, changeset}
            _ -> target_tag
          end
        true -> {:ok, "linked"}
      end
    else
      false -> {:error, "Write permission: Disabled."}
      _ -> {:error, "Tasklist ID not found."}
    end
  end

  def remove_tag_from_tasklist(tasklist_id, user_id, tag_name)
    when is_integer(tasklist_id) and is_integer(user_id) and is_binary(tag_name) do
    
      with(
        tasklist when not is_nil(tasklist) <- (get_tasklist(tasklist_id) |> Repo.preload(:tags)),
        true <- can_write?(user_id, tasklist_id)
      ) do
        
        case t = Repo.one(from r in assoc(tasklist, :tags), where: r.name == ^tag_name) do
          nil -> :ok
          _ ->
            %{
              remove_tag_from_tasklist: ((from x in TasklistTag, where: x.tag_id == ^t.id, where: x.tasklist_id == ^tasklist_id) |> Repo.delete_all),
              delete_tag: Tags.delete_tag(t)
            }
        end
      else
        false -> {:error, "Write permission: Disabled."}
        _ -> {:error, "Tasklist ID not found."}
      end

  end

end
