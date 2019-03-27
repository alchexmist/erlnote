defmodule Erlnote.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Tags.Tag
  alias Erlnote.Notes.{NoteTag, NotepadTag}
  alias Erlnote.Tasks.TasklistTag

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
  Creates a tag (if not exist).

  ## Examples

      iex> create_tag(new_tag_name)
      {:ok, %Tag{}}

  """
  def create_tag(tag_name) when is_binary(tag_name) do
    case t = Repo.one(from r in Tag, where: r.name == ^tag_name) do
      %Tag{} ->
        {:ok, t}
      _ ->
        %Tag{}
        |> Tag.changeset(%{name: tag_name})
        |> Repo.insert()
    end
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

  def count_tag_assoc_records(%Tag{} = t, assoc_name) when is_atom(assoc_name) do
    case assoc_name in [:notepads, :notes, :tasklists] do
      # true -> Repo.preload(t, assoc_name) |> assoc(assoc_name) |> Repo.aggregate(:count, :id)
      true -> assoc(t, assoc_name) |> Repo.aggregate(:count, :id)
      _ -> 0
    end
  end

  @doc """
  Deletes a Tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag_not_found)
      {:error, "Tag not found."}

      iex> delete_tag(tag_in_use)
      {:error, "Tag in use."}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(tag_name) when is_binary(tag_name) do
    case t = get_tag_by_name(tag_name) do
      nil -> {:error, "Tag not found."}
      _ -> delete_tag(t)
    end
  end

  def delete_tag(%Tag{} = tag) when is_map(tag) do
    if(
      count_tag_assoc_records(tag, :notepads) > 0 or
      count_tag_assoc_records(tag, :notes) > 0 or
      count_tag_assoc_records(tag, :tasklists) > 0
    ) do
      {:error, "Tag in use."}
    else
      Repo.delete(tag)
    end
  end

  defp delete_tag_assoc(%Tag{} = t, assoc_name) when is_atom(assoc_name) do
    {q, tag} = case assoc_name do
      :notepads ->
        {(from nt in NotepadTag), (t |> Repo.preload(:notepads))}
      :notes ->
        {(from nt in NoteTag), (t |> Repo.preload(:notes))}
      :tasklists ->
        {(from tt in TasklistTag), (t |> Repo.preload(:tasklists))}
      _ -> {:error, t}
    end

    case {q, tag} do
      {:error, _} -> q
      _ -> (from r in q, where: r.tag_id == ^t.id) |> Repo.delete_all
    end
  end

  def force_delete_tag(tag_name) when is_binary(tag_name) do
    case t = get_tag_by_name(tag_name) do
      nil -> :ok
      _ ->
        %{
          delete_tag_assoc_notepads: delete_tag_assoc(t, :notepads),
          delete_tag_assoc_notes: delete_tag_assoc(t, :notes),
          delete_tag_assoc_tasklists: delete_tag_assoc(t, :tasklists),
          delete_tag: Repo.delete(t)
        }
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
