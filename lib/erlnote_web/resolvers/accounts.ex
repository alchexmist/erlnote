defmodule ErlnoteWeb.Resolvers.Accounts do
  alias Erlnote.Accounts
  import Ecto.Changeset

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
        temp = traverse_errors(ch, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
        |> Jason.encode!
        |> String.replace("\"", "")
        {
          :error, temp
          # temp
          # |> Enum.map_join(", ", fn {key, val} -> ~s{#{key} #{val}} end)
      }
      _ -> r
    end
  end

end