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
  Returns the list of tasklists. Tasklist owner == User ID and deleted == false.

  ## Examples

      iex> list_is_owner_tasklists(1)
      [%Tasklist{}]

      iex> list_is_owner_tasklists(-1)
      []

  """
  def list_is_owner_tasklists(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> Repo.all(from t in assoc(user, :owner_tasklists), where: t.deleted == false)
    end
  end

  @doc """
  Returns the list of tasklists. is_contributor? == User ID.

  ## Examples

      iex> list_is_contributor_tasklists(1)
      [%Note{}]

      iex> list_is_contributor_tasklists(-1)
      []

  """
  def list_is_contributor_tasklists(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> (from t in assoc(user, :tasklists)) |> Repo.all
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
  def get_tasklist(id) when is_integer(id) do
    Repo.one(from t in Tasklist, where: t.id == ^id and t.deleted == false)
  end

  @doc """
  Updates a tasklist.

  ## Examples

      iex> update_tasklist(1, 1, %{field: new_value})
      {:ok, %Tasklist{}}

      iex> update_tasklist(1, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_tasklist(1, -1, %{field: new_value})
      {:error, "Permission denied."}

      iex> update_tasklist(-1, 1, %{field: new_value})
      {:error, "Permission denied."}

  """
  def update_tasklist(user_id, tasklist_id, attrs) when is_integer(user_id) and is_integer(tasklist_id) and is_map(attrs) do
    if can_write?(user_id, tasklist_id) do
      update_tasklist(get_tasklist(tasklist_id), attrs)
    else
      {:error, "Permission denied."}
    end
  end

  @doc """
  Updates a tasklist.

  ## Examples

      iex> update_tasklist(tasklist, %{field: new_value})
      {:ok, %Tasklist{}}

      iex> update_tasklist(tasklist, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  defp update_tasklist(%Tasklist{} = tasklist, attrs) when is_map(tasklist) and is_map(attrs) do
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

      iex> delete_tasklist(tasklist, user_id)
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
        else
          tasklist = Repo.preload tasklist, :users, force: true
          {:ok, tasklist}
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
  # def link_tasklist_to_user(tasklist_id, user_id, can_read, can_write) when is_integer(tasklist_id) and is_integer(user_id) do
  #   user = Accounts.get_user_by_id(user_id)
  #   tasklist = get_tasklist(tasklist_id)
  #   cond do
  #     is_nil(user) or is_nil(tasklist) -> {:error, "user ID or tasklist ID not found."}
  #     (tasklist |> Repo.preload(:user)).user.id == user_id -> {:ok, "linked"}
  #     true ->
  #       Repo.insert(
  #         TasklistUser.changeset(%TasklistUser{}, %{tasklist_id: tasklist.id, user_id: user.id, can_read: can_read, can_write: can_write})
  #       )
  #       # Return {:ok, _} o {:error, changeset}
  #   end
  # end

  # Para unlink usar la función delete_tasklist.
  @doc """
  Adds user_id as a contributor on the tasklist.

  ## Examples

      iex> link_tasklist_to_user(owner_id, tasklist_id, user_id, can_read, can_write)
      {:ok, %TasklistUser{}}

      iex> link_tasklist_to_user(no_owner_id, tasklist_id, user_id, can_read, can_write)
      {:error, "Permission denied."}

      iex> link_tasklist_to_user(owner_id, bad_tasklist_id, user_id, can_read, can_write)
      {:error, "User ID or tasklist ID not found."}

      iex> link_tasklist_to_user(owner_id, tasklist_id, bad_user_id, can_read, can_write)
      {:error, "User ID or tasklist ID not found."}

  """
  def link_tasklist_to_user(owner_id, tasklist_id, user_id, can_read, can_write)
    when is_integer(owner_id)
    and is_integer(tasklist_id)
    and is_integer(user_id)
    and is_boolean(can_read)
    and is_boolean(can_write) do

    with(
      user when not is_nil(user) <- Accounts.get_user_by_id(user_id),
      tasklist when not is_nil(tasklist) <- Repo.preload(get_tasklist(tasklist_id), :user),
      true <- tasklist.user.id == owner_id
    ) do
      cond do
        tasklist.user.id == user_id -> {:ok, "linked"}
        true ->
          Repo.insert(
            TasklistUser.changeset(%TasklistUser{}, %{tasklist_id: tasklist.id, user_id: user.id, can_read: can_read, can_write: can_write})
          )
          # Return {:ok, _} o {:error, changeset}
      end
    else
      nil -> {:error, "User ID or tasklist ID not found."}
      false -> {:error, "Permission denied."}
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

  @doc """
  Enables/Disables read permission for a (contributor, tasklist).

  ## Examples

      iex> set_can_read_from_tasklist(user_id, tasklist_id, boolean)
      {:ok, %TasklistUser{}}

      iex> set_can_read_from_tasklist(bad_user_id, tasklist_id, boolean)
      {:error, _}

      iex> set_can_read_from_tasklist(user_id, bad_tasklist_id, boolean)
      {:error, _}

  """
  def set_can_read_from_tasklist(user_id, tasklist_id, can_read)
    when is_integer(user_id) and is_integer(tasklist_id) and is_boolean(can_read) do
      set_tasklist_user_permissions(user_id, tasklist_id, :can_read, can_read)
  end

  @doc """
  Enables/Disables write permission for a (contributor, tasklist).

  ## Examples

      iex> set_can_write_to_tasklist(user_id, tasklist_id, boolean)
      {:ok, %TasklistUser{}}

      iex> set_can_write_to_tasklist(bad_user_id, tasklist_id, boolean)
      {:error, _}

      iex> set_can_write_to_tasklist(user_id, bad_tasklist_id, boolean)
      {:error, _}

  """
  def set_can_write_to_tasklist(user_id, tasklist_id, can_write)
    when is_integer(user_id) and is_integer(tasklist_id) and is_boolean(can_write) do
      set_tasklist_user_permissions(user_id, tasklist_id, :can_write, can_write)
  end

  defp can_read_or_write?(user_id, tasklist_id) do
    case t = (get_tasklist(tasklist_id) |> Repo.preload(:user)) do
      nil -> {false, false}
      _ ->
        cond do
          user_id == t.user.id -> {true, true}
          true ->
            record = Repo.one(from r in TasklistUser, where: r.tasklist_id == ^t.id, where: r.user_id == ^user_id)
            if is_nil(record) do
              {false, false}
            else
              # can_read & can_write values: true, false or nil.
              {record.can_read == true, record.can_write == true}
            end
        end
    end
  end

  @doc """
  Checks if tasklist can be written by the contributor.

  ## Examples

      iex> can_write?(user_id, tasklist_id)
      true

      iex> can_write?(bad_user_id, tasklist_id)
      {false, false}

      iex> can_write?(user_id, bad_tasklist_id)
      {false, false}

  """
  def can_write?(user_id, tasklist_id) do
    Kernel.elem(can_read_or_write?(user_id, tasklist_id), 1)
  end

  @doc """
  Checks if tasklist can be read by the contributor.

  ## Examples

      iex> can_read?(user_id, tasklist_id)
      true

      iex> can_read?(bad_user_id, tasklist_id)
      {false, false}

      iex> can_read?(user_id, bad_tasklist_id)
      {false, false}

  """
  def can_read?(user_id, tasklist_id) do
    Kernel.elem(can_read_or_write?(user_id, tasklist_id), 0)
  end

  @doc """
  Lists all tasks in the list.

  ## Examples

      iex> list_tasks_from_tasklist(valid_tasklist_id)
      [%Task{}]

      iex> list_tasks_from_tasklist(bad_tasklist_id)
      {:error, "Tasklist ID not found."}

  """
  def list_tasks_from_tasklist(tasklist_id) when is_integer(tasklist_id) do
    case tl = get_tasklist(tasklist_id) do
      nil -> {:error, "Tasklist ID not found."}
      _ -> (from t in assoc(tl, :tasks)) |> Repo.all
        #(tl |> Repo.preload(:tasks)).tasks
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

  @doc """
  Lists all tags associated with a tasklist.

  ## Examples

      iex> get_tags_from_tasklist(tasklist_id)
      [%Tag{}]

      iex> get_tags_from_tasklist(tasklist_without_tags_id)
      []

      iex> get_tags_from_tasklist(bad_tasklist_id)
      []

  """
  def get_tags_from_tasklist(tasklist_id) when is_integer(tasklist_id) do
    with t when not is_nil(t) <- get_tasklist(tasklist_id) do
      (from r in assoc(t, :tags)) |> Repo.all
    else
      nil -> []
    end
  end

  @doc """
  Creates assoc(tasklist, tag).

  ## Examples

      iex> link_tag_to_tasklist(tasklist_id, user_id, tag_name)
      {:ok, %TasklistTag{}}

      iex> link_tag_to_tasklist(tasklist_id, user_id, duplicated_tag_name)
      {:ok, "linked"}

      iex> link_tag_to_tasklist(bad_tasklist_id, user_id, tag_name)
      {:error, "Tasklist ID not found."}

      iex> link_tag_to_tasklist(tasklist_id, bad_user_id, tag_name)
      {:error, "Write permission: Disabled."}

  """
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

  @doc """
  Deletes assoc(tasklist, tag).

  ## Examples

      iex> remove_tag_from_tasklist(tasklist_id, user_id, tag_name_not_in_use_anymore)
      %{remove_tag_from_tasklist: {1, nil}, delete_tag: {:ok, %Tag{}}}

      iex> remove_tag_from_tasklist(tasklist_id, user_id, tag_name_in_use_by_other_entities)
      %{remove_tag_from_tasklist: {1, nil}, delete_tag: {:error, msg_string}}

      iex> remove_tag_from_tasklist(tasklist_id, user_id, nonexistent_tag_name)
      :ok

      iex> remove_tag_from_tasklist(bad_tasklist_id, user_id, tag_name)
      {:error, "Tasklist ID not found."}

      iex> remove_tag_from_tasklist(tasklist_id, bad_user_id, tag_name)
      {:error, "Write permission: Disabled."}

  """
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
