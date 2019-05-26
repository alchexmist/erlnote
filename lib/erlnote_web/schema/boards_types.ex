defmodule ErlnoteWeb.Schema.BoardsTypes do
  use Absinthe.Schema.Notation

  object :board do
    field :id, :id
    field :text, :string
    field :title, :string
  end

  input_object :update_board_input do
    field :id, non_null(:id)
    field :text, :string
    field :title, non_null(:string)
  end

end