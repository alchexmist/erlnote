defmodule Erlnote.Tasks.TasklistUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Tasks.Tasklist
  alias Erlnote.Accounts.User

  schema "tasklists_users" do
    field :can_read, :boolean, default: true
    field :can_write, :boolean, default: true
    # field :tasklist_id, :id
    belongs_to :tasklist, Tasklist, on_replace: :delete
    # field :user_id, :id
    belongs_to :user, User, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def update_read_permission_changeset(tasklist_user, attrs) do
    tasklist_user
    |> cast(attrs, [:can_read, :tasklist_id, :user_id])
    |> validate_required([:can_read, :tasklist_id, :user_id])
    |> unique_constraint(:tasklist_id, name: :tasklists_users_tasklist_id_user_id_index)
  end

  def update_write_permission_changeset(tasklist_user, attrs) do
    tasklist_user
    |> cast(attrs, [:can_write, :tasklist_id, :user_id])
    |> validate_required([:can_write, :tasklist_id, :user_id])
    |> unique_constraint(:tasklist_id, name: :tasklists_users_tasklist_id_user_id_index)
  end

  @doc false
  def changeset(tasklist_user, attrs) do
    tasklist_user
    |> cast(attrs, [:can_read, :can_write, :tasklist_id, :user_id])
    |> validate_required([:can_read, :can_write, :tasklist_id, :user_id])
    |> validate_inclusion(:can_read, [true, false])
    |> validate_inclusion(:can_write, [true, false])
    |> unique_constraint(:tasklist_id, name: :tasklists_users_tasklist_id_user_id_index)
  end
end
