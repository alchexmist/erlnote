defmodule ErlnoteWeb.Schema.TasklistsTypes do
  use Absinthe.Schema.Notation
  
  object :tasklist do
    field :id, :id
    field :title, :string
  end
  
end