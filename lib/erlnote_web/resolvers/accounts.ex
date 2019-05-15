defmodule ErlnoteWeb.Resolvers.Accounts do
  alias Erlnote.Accounts
  alias Erlnote.Helpers.Error

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

  def create_user_account(_, %{input: params}, _) do
    case r = Accounts.create_user(params) do
      {:error, %Ecto.Changeset{} = ch} ->
        {
          :error, Error.changeset_errors_to_json(ch)
        }
      _ -> r
    end
  end

end