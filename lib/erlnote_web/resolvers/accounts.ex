defmodule ErlnoteWeb.Resolvers.Accounts do
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User

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
    Accounts.create_user(params)
    # case r = Accounts.create_user(params) do
    #   {:error, %Ecto.Changeset{} = ch} ->
    #     {
    #       :error,
    #       message: "Could not create user account",
    #       details: Error.changeset_errors_to_string(ch)
    #     }
    #     # Example of response:
    #     # {
    #     #   "errors": [
    #     #     {
    #     #       "path": [
    #     #         "userAccount"
    #     #       ],
    #     #       "message": "Could not create user account",
    #     #       "locations": [
    #     #         {
    #     #           "line": 2,
    #     #           "column": 0
    #     #         }
    #     #       ],
    #     #       "details": {
    #     #         "credentials": [
    #     #           {
    #     #             "password": [
    #     #               "should be at least 8 character(s)"
    #     #             ],
    #     #             "email": [
    #     #               "has invalid format"
    #     #             ]
    #     #           }
    #     #         ]
    #     #       }
    #     #     }
    #     #   ],
    #     #   "data": {
    #     #     "userAccount": null
    #     #   }
    #     # }
    #   _ -> r
    # end
  end

  def login(_, %{email: email, password: password}, _) do
    case Accounts.authenticate(email, password) do
      {:ok, %User{} = u} ->
        token = ErlnoteWeb.Authentication.sign(%{id: u.id})
        {:ok, %{token: token, user: u}}
      error ->
        error # Returns {:error, "Authentication error"}
    end

  end

end