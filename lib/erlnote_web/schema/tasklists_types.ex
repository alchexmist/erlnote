defmodule ErlnoteWeb.Schema.TasklistsTypes do
  use Absinthe.Schema.Notation
  
  object :tasklist do
    field :id, :id
    field :title, :string
  end
  
  input_object :update_tasklist_input do
    field :tasklist_id, non_null(:id)
    field :title, non_null(:string)
  end

end