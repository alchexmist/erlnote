defmodule Erlnote.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Notes.{Notepad, Note}
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User

  @doc """
  Creates a note. Note owner == User ID.

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
  Returns the list of notes. Note owner == User ID.

  ## Examples

      iex> list_is_owner_notes(1)
      [%Note{}]

      iex> list_is_owner_notes(-1)
      []

  """
  def list_is_owner_notes(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> (user |> Repo.preload(:notes)).notes
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
  def get_note(id) when is_integer(id), do: Repo.get(Note, id)

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.update_changeset(attrs)
    |> Repo.update()
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
  Gets a single notepad.

  Raises `Ecto.NoResultsError` if the Notepad does not exist.

  ## Examples

      iex> get_notepad!(123)
      %Notepad{}

      iex> get_notepad!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notepad!(id), do: Repo.get!(Notepad, id)

  @doc """
  Creates a notepad.

  ## Examples

      iex> create_notepad(%{field: value})
      {:ok, %Notepad{}}

      iex> create_notepad(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notepad(attrs \\ %{}) do
    %Notepad{}
    |> Notepad.changeset(attrs)
    |> Repo.insert()
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
  Deletes a Notepad.

  ## Examples

      iex> delete_notepad(notepad)
      {:ok, %Notepad{}}

      iex> delete_notepad(notepad)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notepad(%Notepad{} = notepad) do
    Repo.delete(notepad)
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
end
