defmodule ErlnoteWeb.Schema.TagsTypes do
  use Absinthe.Schema.Notation

  object :tag do
    field :id, non_null(:id)
    field :name, non_null(:string)
  end

end