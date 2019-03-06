defmodule Erlnote.Tasks.Tasklist do
  use Ecto.Schema
  import Ecto.Changeset


  schema "tasklists" do
    field :title, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tasklist, attrs) do
    tasklist
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
