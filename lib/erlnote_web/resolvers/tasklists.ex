defmodule ErlnoteWeb.Resolvers.Tasklists do

  alias Erlnote.Tasks
  alias Erlnote.Accounts

  # mutation {
  #   createTasklist {
  #     id
  #     title
  #   }
  # }
  def create_tasklist(_, _, %{context: %{current_user: %{id: id}}}) do
    Tasks.create_tasklist(id)
  end


end