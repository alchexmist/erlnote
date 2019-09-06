defmodule ErlnoteWeb.Schema.TagsTypes do
  use Absinthe.Schema.Notation

  object :tag do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :tasklist_id, :id
    field :updated_by, :id
  end

end