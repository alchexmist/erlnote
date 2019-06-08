defmodule ErlnoteWeb.Schema.TasklistsTypes do
  use Absinthe.Schema.Notation
  
  object :tasklist do
    field :id, :id
    field :title, :string
    field :tasks, list_of(:task) do
      resolve fn tasklist, _, %{context: %{current_user: %{id: user_id}}} ->
        case r = Erlnote.Tasks.list_tasks_from_tasklist(user_id, tasklist.id) do
          {:error, _} -> r
          _ -> {:ok, r}
        end
      end
    end
  end
  
  input_object :update_tasklist_input do
    field :tasklist_id, non_null(:id)
    field :title, non_null(:string)
  end

  enum :add_tasklist_contributor_filter_type do
    value :id #, as: "id" # Con el "as" se reciben string en lugar de atoms.
    value :username #, as: "username"
  end

  @desc "Filtering options for add contributor"
  input_object :add_tasklist_contributor_filter do
    @desc "ID or USERNAME"
    field :type, non_null(:add_tasklist_contributor_filter_type)
    @desc "String value"
    field :value, non_null(:string)
    @desc "Target tasklist ID"
    field :tid, non_null(:id)
    @desc "Can read?"
    field :can_read, non_null(:boolean)
    @desc "Can write?"
    field :can_write, non_null(:boolean)
  end

  input_object :update_tasklist_access_input do
    field :user_id, non_null(:id)
    field :tasklist_id, non_null(:id)
    field :can_read, non_null(:boolean)
    field :can_write, non_null(:boolean)
  end

end