defmodule Erlnote.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Notes.{Notepad, NotepadTag, NoteTag, Note}
  alias Erlnote.Tasks.{Tasklist, TasklistTag}

  @name_min_len 1
  @name_max_len 255

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.
  
  schema "tags" do
    field :name, :string
    many_to_many :notepads, Notepad, join_through: NotepadTag, on_replace: :delete
    many_to_many :notes, Note, join_through: NoteTag, on_replace: :delete
    many_to_many :tasklists, Tasklist, join_through: TasklistTag, on_replace: :delete
    
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: @name_min_len, max: @name_max_len)
    |> unique_constraint(:name)
  end
end
