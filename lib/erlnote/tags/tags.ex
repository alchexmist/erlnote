defmodule Erlnote.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Tags.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Returns nil if the Tag does not exist.

  ## Examples

      iex> get_tag(123)
      %Tag{}

      iex> get_tag(456)
      nil

  """
  def get_tag(id) when is_integer(id), do: Repo.get(Tag, id)

  @doc """
  Gets a single tag.

  Returns nil if the Tag does not exist.

  ## Examples

      iex> get_tag_by_name("abc")
      %Tag{}

      iex> get_tag_by_name("zsh")
      nil

  """
  def get_tag_by_name(tag_name) when is_binary(tag_name), do: Repo.get_by(Tag, name: tag_name)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(tag_name) when is_binary(tag_name) do
    case t = get_tag_by_name(tag_name) do
      nil -> {:error, "Tag name not found."}
      _ ->
        t = (t |> Repo.preload([:notepads, :notes, :tasklists]))
        if length(t.notepads) > 0 or length(t.notes) > 0 or length(t.tasklists) > 0 do
          {:error, "Tag in use."}
        else
          Repo.delete(t)
        end
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{source: %Tag{}}

  """
  def change_tag(%Tag{} = tag) do
    Tag.changeset(tag, %{})
  end
end
