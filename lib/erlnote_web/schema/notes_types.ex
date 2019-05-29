defmodule ErlnoteWeb.Schema.NotesTypes do
  use Absinthe.Schema.Notation

  object :note do
    field :id, :id
    field :body, :string
    field :title, :string
  end

  

end