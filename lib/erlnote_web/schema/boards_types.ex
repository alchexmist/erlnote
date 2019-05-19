defmodule ErlnoteWeb.Schema.BoardsTypes do
  use Absinthe.Schema.Notation

  object :board do
    field :id, :id
    field :text, :string
    field :title, :string
  end

end