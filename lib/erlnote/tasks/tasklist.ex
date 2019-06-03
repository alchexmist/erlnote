defmodule Erlnote.Tasks.Tasklist do
  use Ecto.Schema
  import Ecto.Changeset

  @max_title_len 255
  @min_title_len 1

  alias Erlnote.Accounts.User
  alias Erlnote.Tasks.{TasklistUser, TasklistTag, Task}
  alias Erlnote.Tags.Tag

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.
  
  schema "tasklists" do
    field :title, :string
    field :deleted, :boolean, default: false
    # field :user_id, :id
    belongs_to :user, User, on_replace: :delete
    has_many :tasks, Task, on_replace: :delete
    many_to_many :users, User, join_through: TasklistUser, on_replace: :delete
    many_to_many :tags, Tag, join_through: TasklistTag, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def update_changeset(tasklist, params) do
    tasklist
    |> cast(params, [:deleted, :title])
    |> validate_required([:title])
    # |> validate_required([:deleted])
    |> validate_length(:title, min: @min_title_len, max: @max_title_len)
  end

  @doc false
  def create_changeset(tasklist, params) do
    tasklist
    |> cast(params, [:deleted])
    |> validate_required([:deleted])
    |> validate_inclusion(:deleted, [true, false])
    |> changeset(params)
  end

  @doc false
  def changeset(tasklist, attrs) do
    tasklist
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> validate_length(:title, min: @min_title_len, max: @max_title_len)
  end
end
