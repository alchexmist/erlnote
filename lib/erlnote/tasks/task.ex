defmodule Erlnote.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Tasks.Tasklist

  schema "tasks" do
    field :description, :string
    field :end_datetime, :utc_datetime
    field :name, :string
    field :priority, :string, default: "NORMAL"
    field :start_datetime, :utc_datetime
    field :state, :string, default: "INPROGRESS"
    belongs_to :tasklist, Tasklist, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:state, :description, :start_datetime, :end_datetime, :priority, :name])
    |> validate_required([:state, :description, :start_datetime, :end_datetime, :priority, :name])
  end
end
