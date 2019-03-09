defmodule Erlnote.Tasks.Tasklist do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.User
  alias Erlnote.Tasks.{TasklistUser, TasklistTag, Task}
  alias Erlnote.Tags.Tag

  # If your :join_through is a schema, your join table may be structured as
  # any other table in your codebase, including timestamps. You may define
  # a table with primary keys.
  
  schema "tasklists" do
    field :title, :string
    # field :user_id, :id
    belongs_to :user, User, on_replace: :delete
    has_many :tasks, Task, on_replace: :delete
    many_to_many :users, User, join_through: TasklistUser
    many_to_many :tags, Tag, join_through: TasklistTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tasklist, attrs) do
    tasklist
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
