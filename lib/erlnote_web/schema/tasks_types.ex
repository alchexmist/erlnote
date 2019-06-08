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
    field :tasklist_id, :id
  end

  input_object :update_task_input do
    field :id, non_null(:id)
    field :tasklist_id, non_null(:id)
    field :state, :string
    field :description, :string
    field :start_datetime, :datetime
    field :end_datetime, :datetime
    field :priority, :string
    field :name, :string
  end

end