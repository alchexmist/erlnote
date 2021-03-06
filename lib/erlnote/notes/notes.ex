defmodule Erlnote.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Notes.{Notepad, NotepadTag, Note, NoteUser, NoteTag}
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User
  alias Erlnote.Tags
  alias Erlnote.Tags.Tag

  @doc """
  Creates a empty note. Note owner == User ID.

  ## Examples

      iex> create_note(1)
      {:ok, %Note{}}

      iex> create_note(-1)
      {:error, %Ecto.Changeset{}}

  """
  def create_note(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil ->
        {
          :error,
          change(%Note{}, %{user: %User{id: user_id}})
          |> add_error(:user, user_id |> Integer.to_string, additional: "User ID not found.")
        }
      _ ->
        build_assoc(user, :notes)
        |> Note.create_changeset(%{title: "note-" <> Ecto.UUID.generate, deleted: false})
        |> Repo.insert()
    end
  end

  @doc """
  Returns the list of notes. Note owner == User ID and deleted == false.

  ## Examples

      iex> list_is_owner_notes(1)
      [%Note{}]

      iex> list_is_owner_notes(-1)
      []

  """
  def list_is_owner_notes(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> Repo.all(from n in assoc(user, :notes), where: n.deleted == false)
    end
  end

  @doc """
  Returns the list of notes. is_collaborator? == User ID.

  ## Examples

      iex> list_is_collaborator_notes(1)
      [%Note{}]

      iex> list_is_collaborator_notes(-1)
      []

  """
  def list_is_collaborator_notes(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> (from n in assoc(user, :collaborator_notes)) |> Repo.all
    end
  end

  @doc """
  Gets a single note.

  Returns nil if the note does not exist.

  ## Examples

      iex> get_note(1)
      %Note{}

      iex> get_note(-1)
      nil

  """
  def get_note(id) when is_integer(id) do
    Repo.one(from n in Note, where: n.id == ^id and n.deleted == false)
  end

  def get_note_include_deleted(id) when is_integer(id) do
    Repo.one(from n in Note, where: n.id == ^id)
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(1, 1, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(1, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_note(1, -1, %{field: new_value})
      {:error, "Permission denied."}

      iex> update_note(-1, 1, %{field: new_value})
      {:error, "Permission denied."}

  """
  def update_note(user_id, note_id, attrs) when is_integer(user_id) and is_integer(note_id) and is_map(attrs) do
    if can_write?(user_id, note_id) do
      update_note(get_note(note_id), attrs)
    else
      {:error, "Permission denied."}
    end
  end

  # @doc """
  # Updates a note.

  # ## Examples

  #     iex> update_note(note, %{field: new_value})
  #     {:ok, %Note{}}

  #     iex> update_note(note, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  defp update_note(%Note{} = note, attrs) when is_map(note) and is_map(attrs) do
    note
    |> Note.update_changeset(attrs)
    |> Repo.update()
  end

  # Para unlink usar la función delete_note.
  @doc """
  Adds user_id as a collaborator on the note.

  ## Examples

      iex> link_note_to_user(owner_id, note_id, user_id, can_read, can_write)
      {:ok, %NoteUser{}}

      iex> link_note_to_user(no_owner_id, note_id, user_id, can_read, can_write)
      {:error, "Permission denied."}

      iex> link_note_to_user(owner_id, bad_note_id, user_id, can_read, can_write)
      {:error, "User ID or note ID not found."}

      iex> link_note_to_user(owner_id, note_id, bad_user_id, can_read, can_write)
      {:error, "User ID or note ID not found."}

  """
  def link_note_to_user(owner_id, note_id, user_id, can_read, can_write)
    when is_integer(owner_id)
    and is_integer(note_id)
    and is_integer(user_id)
    and is_boolean(can_read)
    and is_boolean(can_write) do

    with(
      user when not is_nil(user) <- Accounts.get_user_by_id(user_id),
      note when not is_nil(note) <- Repo.preload(get_note(note_id), :user),
      true <- note.user.id == owner_id
    ) do
      cond do
        # (note |> Repo.preload(:user)).user.id == user_id -> {:ok, "linked"}
        note.user.id == user_id -> {:ok, "linked"}
        true ->
          Repo.insert(
            NoteUser.changeset(%NoteUser{}, %{note_id: note.id, user_id: user.id, can_read: can_read, can_write: can_write})
          )
          # Return {:ok, _} o {:error, changeset}
      end
    else
      nil -> {:error, "User ID or note ID not found."}
      false -> {:error, "Permission denied."}
    end
  end

  defp set_note_user_permissions(user_id, note_id, pname, pvalue) do
    case Repo.one(
        from r in NoteUser,
        where: r.user_id == ^user_id,
        where: r.note_id == ^note_id
      ) do
        nil -> {:error, "User-Note assoc: not found."}
        x ->
          case pname do
            :can_read ->
              x
              |> NoteUser.update_read_permission_changeset(%{note_id: note_id, user_id: user_id, can_read: pvalue})
              |> Repo.update()
            :can_write ->
              x
              |> NoteUser.update_write_permission_changeset(%{note_id: note_id, user_id: user_id, can_write: pvalue})
              |> Repo.update()
          end
      end
  end

  @doc """
  Enables/Disables read permission for a (contributor, note).

  ## Examples

      iex> set_can_read_from_note(user_id, note_id, boolean)
      {:ok, %NoteUser{}}

      iex> set_can_read_from_note(bad_user_id, note_id, boolean)
      {:error, _}

      iex> set_can_read_from_note(user_id, bad_note_id, boolean)
      {:error, _}

  """
  def set_can_read_from_note(user_id, note_id, can_read)
    when is_integer(user_id) and is_integer(note_id) and is_boolean(can_read) do
      set_note_user_permissions(user_id, note_id, :can_read, can_read)
  end

  @doc """
  Enables/Disables write permission for a (contributor, note).

  ## Examples

      iex> set_can_write_to_note(user_id, note_id, boolean)
      {:ok, %NoteUser{}}

      iex> set_can_write_to_note(bad_user_id, note_id, boolean)
      {:error, _}

      iex> set_can_write_to_note(user_id, bad_note_id, boolean)
      {:error, _}

  """
  def set_can_write_to_note(user_id, note_id, can_write)
    when is_integer(user_id) and is_integer(note_id) and is_boolean(can_write) do
      set_note_user_permissions(user_id, note_id, :can_write, can_write)
  end

  defp can_read_or_write?(user_id, note_id) do
    case n = (get_note(note_id) |> Repo.preload(:user)) do
      nil -> {false, false}
      _ ->
        cond do
          user_id == n.user.id -> {true, true}
          true ->
            record = Repo.one(from r in NoteUser, where: r.note_id == ^n.id, where: r.user_id == ^user_id)
            if is_nil(record) do
              {false, false}
            else
              # can_read & can_write values: true, false or nil.
              {record.can_read == true, record.can_write == true}
            end
        end
    end
  end

  def get_access_info(user_id, note_id) when is_integer(user_id) and is_integer(note_id) do
      case {can_read, can_write} = can_read_or_write?(user_id, note_id) do
        {false, false} -> {:error, "unauthorized"}
        _ ->
          case note = get_note(note_id) do
            nil -> {:error, "invalid data"}
            _ ->
              r = %{note_id: note.id, owner_id: note.user_id, user_id: user_id, can_read: can_read, can_write: can_write}
              IO.inspect r
              {:ok, r}
          end
      end
  end

  @doc """
  Checks if note can be written by the contributor.

  ## Examples

      iex> can_write?(user_id, note_id)
      true

      iex> can_write?(bad_user_id, note_id)
      false

      iex> can_write?(user_id, bad_note_id)
      false

  """
  def can_write?(user_id, note_id) do
    Kernel.elem(can_read_or_write?(user_id, note_id), 1)
  end

  @doc """
  Checks if note can be read by the contributor.

  ## Examples

      iex> can_read?(user_id, note_id)
      true

      iex> can_read?(bad_user_id, note_id)
      false

      iex> can_read?(user_id, bad_note_id)
      false

  """
  def can_read?(user_id, note_id) do
    Kernel.elem(can_read_or_write?(user_id, note_id), 0)
  end

  @doc """
  Lists all tags associated with a note.

  ## Examples

      iex> get_tags_from_note(note_id)
      [%Tag{}]

      iex> get_tags_from_note(note_without_tags_id)
      []

      iex> get_tags_from_note(bad_note_id)
      []

  """
  def get_tags_from_note(note_id) when is_integer(note_id) do
    with n when not is_nil(n) <- get_note(note_id) do
      (from r in assoc(n, :tags)) |> Repo.all
    else
      nil -> []
    end
  end

  @doc """
  Creates assoc(note, tag).

  ## Examples

      iex> link_tag_to_note(note_id, user_id, tag_name)
      {:ok, %NoteTag{}}

      iex> link_tag_to_note(note_id, user_id, duplicated_tag_name)
      {:ok, "linked"}

      iex> link_tag_to_note(bad_note_id, user_id, tag_name)
      {:error, "Note ID not found."}

      iex> link_tag_to_note(note_id, bad_user_id, tag_name)
      {:error, "Write permission: Disabled."}

  """
  def link_tag_to_note(note_id, user_id, tag_name)
    when is_integer(note_id) and is_integer(user_id) and is_binary(tag_name) do

    with(
      note when not is_nil(note) <- get_note(note_id),
      true <- can_write?(user_id, note_id)
    ) do
      cond do
        is_nil(Repo.one(from t in assoc(note, :tags), where: t.name == ^tag_name)) ->
          case {_, target_tag} = Tags.create_tag(tag_name) do
            {:ok, %Tag{}} ->
              Repo.insert(
                NoteTag.changeset(%NoteTag{}, %{note_id: note.id, tag_id: target_tag.id})
              )
              # Return {:ok, _} o {:error, changeset}
            _ -> {:error, target_tag}
          end
        true -> {:ok, "linked"}
      end
    else
      false -> {:error, "Write permission: Disabled."}
      _ -> {:error, "Note ID not found."}
    end
  end

  @doc """
  Deletes assoc(note, tag).

  ## Examples

      iex> remove_tag_from_note(note_id, user_id, tag_name_not_in_use_anymore)
      %{remove_tag_from_note: {1, nil}, delete_tag: {:ok, %Tag{}}}

      iex> remove_tag_from_note(note_id, user_id, tag_name_in_use_by_other_entities)
      %{remove_tag_from_note: {1, nil}, delete_tag: {:error, msg_string}}

      iex> remove_tag_from_note(note_id, user_id, nonexistent_tag_name)
      :ok

      iex> remove_tag_from_note(bad_note_id, user_id, tag_name)
      {:error, "Note ID not found."}

      iex> remove_tag_from_note(note_id, bad_user_id, tag_name)
      {:error, "Write permission: Disabled."}

  """
  def remove_tag_from_note(note_id, user_id, tag_name)
    when is_integer(note_id) and is_integer(user_id) and is_binary(tag_name) do
    
      with(
        note when not is_nil(note) <- get_note(note_id),
        true <- can_write?(user_id, note_id)
      ) do
        
        case t = Repo.one(from r in assoc(note, :tags), where: r.name == ^tag_name) do
          nil -> :ok
          _ ->
            %{
              remove_tag_from_note: ((from x in NoteTag, where: x.tag_id == ^t.id, where: x.note_id == ^note_id) |> Repo.delete_all),
              delete_tag: Tags.delete_tag(t)
            }
        end
      else
        false -> {:error, "Write permission: Disabled."}
        _ -> {:error, "Note ID not found."}
      end

  end

  defp get_note_tags(%Note{} = n) do
    (Repo.preload(n, :tags)).tags
    |> Enum.map(fn x -> x.id end)
  end

  defp delete_note_tags(%Note{} = n, tag_id_list) do
    (from nt in NoteTag, where: nt.tag_id in ^tag_id_list, where: nt.note_id == ^n.id)
    |> Repo.delete_all
    Enum.map(tag_id_list, fn x -> Tags.delete_tag(Tags.get_tag(x)) end)
  end

  defp delete_note(%Note{} = n) do
    tag_list = get_note_tags(n)
    r = Repo.delete(n)
    delete_note_tags(n, tag_list)
    r
  end

  @doc """
  Deletes a Note in the name of the user with ID == user_id.

  ## Examples

      iex> delete_note(note, user_id)
      {:ok, %Note{}}

      iex> delete_note(note, user_id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note, user_id) when is_integer(user_id) do
    note = (note |> Repo.preload([:user, :users]))
    cond do
      note.users == [] and user_id == note.user_id -> # Note without users (Owner)
        delete_note(note)
      user_id == note.user_id -> # Note with users (Owner)
        update_note(note, %{deleted: true})
      true ->
        from(r in NoteUser, where: r.user_id == ^user_id, where: r.note_id == ^note.id) |> Repo.delete_all

        if Repo.all(from(u in NoteUser, where: u.note_id == ^note.id)) == [] and note.deleted do
          delete_note(note)
        else
          note = Repo.preload note, :users, force: true
          {:ok, note}
        end
    end
  end

  @doc """
  Returns the list of notepads.

  ## Examples

      iex> list_notepads()
      [%Notepad{}, ...]

  """
  def list_notepads do
    Repo.all(Notepad)
  end

  @doc """
  Returns the list of notepads such that User ID == Notepad owner.

  ## Examples

      iex> list_notepads(valid_user_id)
      [%Notepad{}, ...]

      iex> list_notepads(bad_user_id)
      []

  """
  def list_notepads(user_id) when is_integer(user_id) do
    with(
      user when not is_nil(user) <- (Accounts.get_user_by_id(user_id) |> Repo.preload(:notepads, force: true))
    ) do
      user.notepads
    else
      nil -> []
    end
  end

  @doc """
  Gets a single notepad.

  Returns nil if the Notepad does not exist.

  ## Examples

      iex> get_notepad(1)
      %Notepad{}

      iex> get_notepad(456)
      nil

  """
  def get_notepad(id) when is_integer(id), do: Repo.get(Notepad, id)

  def get_notepad(_), do: nil

  def get_notepad_from_note(%Note{} = n) do
    get_notepad(n.notepad_id)
  end

  @doc """
  Creates a notepad. Notepad owner == User ID.

  ## Examples

      iex> create_notepad(1)
      {:ok, %Notepad{}}

      iex> create_notepad(-1)
      {:error, %Ecto.Changeset{}}

  """
  def create_notepad(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil ->
        {
          :error,
          change(%Notepad{}, %{user: %User{id: user_id}})
          |> add_error(:user, user_id |> Integer.to_string, additional: "User ID not found.")
        }
      _ ->
        build_assoc(user, :notepads)
        |> Notepad.changeset(%{name: "notepad-" <> Ecto.UUID.generate})
        |> Repo.insert()
    end
  end

  @doc """
  Updates a notepad.

  ## Examples

      iex> update_notepad(owner_id, notepad, %{field: new_value})
      {:ok, %Notepad{}}

      iex> update_notepad(owner_id, notepad, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      ex> update_notepad(not_owner_id, notepad, %{field: new_value})
      {:error, "Permission denied."}

  """
  def update_notepad(user_id, %Notepad{} = notepad, attrs) when is_integer(user_id) do
    if notepad.user_id == user_id do
      update_notepad(notepad, attrs)
    else
      {:error, "Permission denied."}
    end
  end

  @doc """
  Updates a notepad.

  ## Examples

      iex> update_notepad(notepad, %{field: new_value})
      {:ok, %Notepad{}}

      iex> update_notepad(notepad, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notepad(%Notepad{} = notepad, attrs) do
    notepad
    |> Notepad.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notepad changes.

  ## Examples

      iex> change_notepad(notepad)
      %Ecto.Changeset{source: %Notepad{}}

  """
  def change_notepad(%Notepad{} = notepad) do
    Notepad.changeset(notepad, %{})
  end

  @doc """
  Creates assoc(note, notepad).

  ## Examples

      iex> add_note_to_notepad(valid_note_id, valid_notepad_id)
      {:ok, %Note{}}

      ex> add_note_to_notepad(valid_note_id, valid_notepad_id)
      {:error, "There is already another notepad associated."}

      iex> add_note_to_notepad(bad_note_id, valid_notepad_id)
      {:error, msg}

      iex> add_note_to_notepad(valid_note_id, bad_notepad_id)
      {:error, msg}

  """
  def add_note_to_notepad(note_id, notepad_id) when is_integer(note_id) and is_integer(notepad_id) do
    with(
      note when not is_nil(note) <- get_note(note_id),
      notepad_id_is_nil when is_nil(notepad_id_is_nil) <- note.notepad_id,
      notepad when not is_nil(notepad) <- get_notepad(notepad_id)
    ) do
      note
      |> Note.update_changeset(%{notepad_id: notepad.id})
      |> Repo.update()
    else
      nil -> {:error, "Note ID or Notepad ID not found."}
      _ -> {:error, "There is already another notepad associated."}
    end
  end

  @doc """
  Creates assoc(note, notepad).

  ## Examples

      iex> add_note_to_notepad(user_id, valid_note_id, valid_notepad_id)
      {:ok, %Note{}}

      ex> add_note_to_notepad(user_id, valid_note_id, valid_notepad_id)
      {:error, "There is already another notepad associated."}

      iex> add_note_to_notepad(user_id, bad_note_id, valid_notepad_id)
      {:error, msg}

      iex> add_note_to_notepad(user_id, valid_note_id, bad_notepad_id)
      {:error, msg}

      iex> add_note_to_notepad(not_can_read_user_id, valid_note_id, bad_notepad_id)
      {:error, msg}

      iex> add_note_to_notepad(no_notepad_owner_user_id, valid_note_id, bad_notepad_id)
      {:error, msg}

  """
  def add_note_to_notepad(user_id, note_id, notepad_id) when is_integer(user_id) and is_integer(note_id) and is_integer(notepad_id) do
    with(
      note when not is_nil(note) <- get_note(note_id),
      notepad_id_is_nil when is_nil(notepad_id_is_nil) <- note.notepad_id,
      notepad when not is_nil(notepad) <- get_notepad(notepad_id),
      true <- notepad.user_id == user_id,
      true <- can_read?(user_id, note_id)
    ) do
      note
      |> Note.update_changeset(%{notepad_id: notepad.id})
      |> Repo.update()
    else
      nil -> {:error, "Note ID or Notepad ID not found."}
      false -> {:error, "Permission denied."}
      _ -> {:error, "There is already another notepad associated."}
    end
  end

  @doc """
  Deletes assoc(note, notepad). Returns error if the note does not exist in the notepad.

  ## Examples

      iex> remove_note_from_notepad(valid_note_id, valid_notepad_id)
      {:ok, %Note{}}

      iex> remove_note_from_notepad(bad_note_id, valid_notepad_id)
      {:error, msg}

      iex> remove_note_from_notepad(valid_note_id, bad_notepad_id)
      {:error, msg}

  """
  def remove_note_from_notepad(note_id, notepad_id) when is_integer(note_id) and is_integer(notepad_id) do
    with(
      notepad when not is_nil(notepad) <- get_notepad(notepad_id),
      note when not is_nil(note) <- Repo.one(from r in assoc(notepad, :notes), where: r.id == ^note_id)
    ) do
      note
      |> Note.update_changeset(%{notepad_id: nil})
      |> Repo.update()
    else
      nil -> {:error, "Note ID or Notepad ID not found."}
    end
  end

  @doc """
  Deletes assoc(note, notepad). Returns error if the note does not exist in the notepad.

  ## Examples

      iex> remove_note_from_notepad(owner_id, valid_note_id, valid_notepad_id)
      {:ok, %Note{}}

      iex> remove_note_from_notepad(owner_id, bad_note_id, valid_notepad_id)
      {:error, msg}

      iex> remove_note_from_notepad(owner_id, valid_note_id, bad_notepad_id)
      {:error, msg}

      iex> remove_note_from_notepad(not_owner_id, valid_note_id, bad_notepad_id)
      {:error, msg}

  """
  def remove_note_from_notepad(owner_id, note_id, notepad_id) when is_integer(owner_id) and is_integer(note_id) and is_integer(notepad_id) do
    with(
      notepad when not is_nil(notepad) <- get_notepad(notepad_id),
      true <- owner_id == notepad.user_id,
      note when not is_nil(note) <- Repo.one(from r in assoc(notepad, :notes), where: r.id == ^note_id)
    ) do
      note
      |> Note.update_changeset(%{notepad_id: nil})
      |> Repo.update()
    else
      nil -> {:error, "Note ID or Notepad ID not found."}
      false -> {:error, "Permission denied."}
    end
  end

  @doc """
  Creates assoc(notepad, tag).

  ## Examples

      iex> link_tag_to_notepad(notepad_id, user_id, tag_name)
      {:ok, %NotepadTag{}}

      iex> link_tag_to_notepad(notepad_id, user_id, duplicated_tag_name)
      {:ok, "linked"}

      iex> link_tag_to_notepad(bad_note_id, user_id, tag_name)
      {:error, "Notepad ID not found."}

      iex> link_tag_to_notepad(notepad_id, bad_user_id, tag_name)
      {:error, "Write permission: Disabled."}

  """
  def link_tag_to_notepad(notepad_id, user_id, tag_name)
    when is_integer(notepad_id) and is_integer(user_id) and is_binary(tag_name) do

    with(
      notepad when not is_nil(notepad) <- get_notepad(notepad_id),
      true <- notepad.user_id == user_id
    ) do
      
      cond do
        is_nil(Repo.one(from t in assoc(notepad, :tags), where: t.name == ^tag_name)) ->
          case {_, target_tag} = Tags.create_tag(tag_name) do
            {:ok, %Tag{}} ->
              Repo.insert(
                          NotepadTag.changeset(%NotepadTag{}, %{notepad_id: notepad.id, tag_id: target_tag.id})
              )
              # Return {:ok, _} o {:error, changeset}
            _ -> {:error, target_tag}
          end
        true -> {:ok, "linked"}
      end
    else
      false -> {:error, "Write permission: Disabled."}
      _ -> {:error, "Notepad ID not found."}
    end
  end

  @doc """
  Lists all tags associated with a notepad.

  ## Examples

      iex> get_tags_from_notepad(notepad_id)
      [%Tag{}]

      iex> get_tags_from_notepad(notepad_without_tags_id)
      []

      iex> get_tags_from_notepad(bad_notepad_id)
      []

  """
  def get_tags_from_notepad(notepad_id) when is_integer(notepad_id) do
    with n when not is_nil(n) <- get_notepad(notepad_id) do
      (from r in assoc(n, :tags)) |> Repo.all
    else
      nil -> []
    end
  end

  @doc """
  Deletes assoc(notepad, tag).

  ## Examples

      iex> remove_tag_from_notepad(notepad_id, user_id, tag_name_not_in_use_anymore)
      %{remove_tag_from_notepad: {1, nil}, delete_tag: {:ok, %Tag{}}}

      iex> remove_tag_from_notepad(notepad_id, user_id, tag_name_in_use_by_other_entities)
      %{remove_tag_from_notepad: {1, nil}, delete_tag: {:error, msg_string}}

      iex> remove_tag_from_notepad(notepad_id, user_id, nonexistent_tag_name)
      :ok

      iex> remove_tag_from_notepad(bad_note_id, user_id, tag_name)
      {:error, "Notepad ID not found."}

      iex> remove_tag_from_notepad(notepad_id, bad_user_id, tag_name)
      {:error, "Write permission: Disabled."}

  """
  def remove_tag_from_notepad(notepad_id, user_id, tag_name)
    when is_integer(notepad_id) and is_integer(user_id) and is_binary(tag_name) do
    
      with(
        notepad when not is_nil(notepad) <- get_notepad(notepad_id),
        true <- notepad.user_id == user_id
      ) do
        
        case t = Repo.one(from r in assoc(notepad, :tags), where: r.name == ^tag_name) do
          nil -> :ok
          _ ->
            %{
              remove_tag_from_notepad: ((from x in NotepadTag, where: x.tag_id == ^t.id, where: x.notepad_id == ^notepad_id) |> Repo.delete_all),
              delete_tag: Tags.delete_tag(t)
            }
        end
      else
        false -> {:error, "Write permission: Disabled."}
        _ -> {:error, "Notepad ID not found."}
      end

  end

  defp get_notepad_tags(%Notepad{} = n) do
    (Repo.preload(n, :tags)).tags
    |> Enum.map(fn x -> x.id end)
  end

  defp delete_notepad_tags(%Notepad{} = n, tag_id_list) do
    (from nt in NotepadTag, where: nt.tag_id in ^tag_id_list, where: nt.notepad_id == ^n.id)
    |> Repo.delete_all
    Enum.map(tag_id_list, fn x -> Tags.delete_tag(Tags.get_tag(x)) end)
  end

  defp delete_notepad(%Notepad{} = n) do
    tag_list = get_notepad_tags(n)
    r = Repo.delete(n)
    delete_notepad_tags(n, tag_list)
    r
  end

  @doc """
  Deletes a Notepad in the name of the user with ID == user_id == Owner.

  ## Examples

      iex> delete_notepad(notepad, user_id)
      {:ok, %Notepad{}}

      iex> delete_notepad(notepad, user_id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notepad(%Notepad{} = notepad, user_id) when is_integer(user_id) do
    cond do
      user_id == notepad.user_id -> delete_notepad(notepad)
      true -> {:error, "Permission denied."}
    end
  end

  def get_notes_in_notepad(notepad_id) when is_integer(notepad_id) do
    case n = get_notepad(notepad_id) do
      nil -> []
      _ -> (n |> (Repo.preload(:notes, force: true))).notes
    end
  end

end
