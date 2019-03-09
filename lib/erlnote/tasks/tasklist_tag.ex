defmodule Erlnote.Tasks.TasklistTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Tasks.Tasklist
  alias Erlnote.Tags.Tag

  schema "tasklists_tags" do
    #field :tasklist_id, :id
    belongs_to :tasklist, Tasklist, on_replace: :delete
    #field :tag_id, :id
    belongs_to :tag, Tag, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tasklist_tag, attrs) do
    tasklist_tag
    |> cast(attrs, [:tasklist_id, :tag_id])
    |> validate_required([:tasklist_id, :tag_id])
    |> unique_constraint(:tasklist_id, name: :tasklists_tags_tasklist_id_tag_id_index)
  end
end
