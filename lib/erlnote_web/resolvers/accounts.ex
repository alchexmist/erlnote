defmodule ErlnoteWeb.Resolvers.Accounts do
  alias Erlnote.Accounts

  def users(_, _, _) do
    {:ok, Accounts.list_users()}
  end

  def user(_, %{filter: opts}, _) do
    case opts do
      %{type: :id, value: i} when is_binary(i) -> 
        case Integer.parse(i) do
          {i, _} -> {:ok, Accounts.get_user_by_id(i)}
          _ -> {:error, "Bad argument"}
        end
      %{type: :username, value: u} when is_binary(u) -> {:ok, Accounts.get_user_by_username(u)}
    end
  end

end