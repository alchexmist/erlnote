defmodule ErlnoteWeb.Schema.NotesTypes do
  use Absinthe.Schema.Notation

  object :note do
    field :id, :id
    field :body, :string
    field :title, :string
  end

  input_object :update_note_input do
    field :id, non_null(:id)
    field :body, :string
    field :title, non_null(:string)
  end

end