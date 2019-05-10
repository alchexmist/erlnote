defmodule ErlnoteWeb.Resolvers.Accounts do
  alias Erlnote.Accounts

  def users(_, _, _) do
    {:ok, Accounts.list_users()}
  end

  def user(_, %{username: u}, _) when is_binary(u) do
    {:ok, Accounts.get_user_by_username(u)}
  end

end