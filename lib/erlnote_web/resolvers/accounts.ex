defmodule ErlnoteWeb.Resolvers.Accounts do
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User
  alias Erlnote.Boards
  alias Erlnote.Notes
  alias Erlnote.Tasks
  
  def me(_, _, %{context: %{current_user: current_user}}) do
    {:ok,
      %{current_user |
        owner_boards: Boards.list_is_owner_boards(current_user.id),
        boards: Boards.list_is_contributor_boards(current_user.id),
        notes: Notes.list_is_owner_notes(current_user.id),
        collaborator_notes: Notes.list_is_collaborator_notes(current_user.id),
        notepads: Notes.list_notepads(current_user.id),
        owner_tasklists: Tasks.list_is_owner_tasklists(current_user.id)
      }
    }
    # {:ok, Map.put(current_user, :owner_boards, Boards.list_is_owner_boards(current_user.id))}
  end
  def me(_, _, _) do
    {:ok, nil}
  end

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

  # mutation {
  #   login(email: "asm@example.com", password: "altosecreto") {
  #     token
  #     user {
  #       id
  #       name
  #       username
  #     }
  #   }
  # }
  # RESPONSE
  # {
  #   "data": {
  #     "login": {
  #       "user": {
  #         "username": "asm",
  #         "name": "asm",
  #         "id": "1"
  #       },
  #       "token": "SFMyNTY.g3QAAAACZAAEZGF0YXQAAAABZAACaWRhAWQABnNpZ25lZG4GAChNvtBqAQ.alz4Lfr6wfXMX-PDPzX71Taamn-Se5mCceLaW05zWJw"
  #     }
  #   }
  # }
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