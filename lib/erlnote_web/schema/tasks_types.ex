defmodule ErlnoteWeb.Schema.TasksTypes do
  use Absinthe.Schema.Notation

  object :task do
    field :id, :id
    field :name, :string
    field :description, :string
    field :state, :string
    field :priority, :string
    field :start_datetime, :datetime
    field :end_datetime, :datetime
  end

end