defmodule Erlnote.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Notes.Notepad

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
