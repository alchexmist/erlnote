defmodule ErlnoteWeb.Schema do
  use Absinthe.Schema

  import_types __MODULE__.AccountsTypes
  import_types __MODULE__.BoardsTypes

  alias ErlnoteWeb.Resolvers
  alias ErlnoteWeb.Schema.Middleware

  query do
    import_fields :accounts_queries

    # End query
  end

  mutation do
    # Mutation fields will go here!
    field :create_user_account, :user do
      arg :input, non_null(:user_account_input)
      resolve &Resolvers.Accounts.create_user_account/3
      #middleware Middleware.ChangesetErrors, "Could not create user account"
    end

    field :login, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      resolve &Resolvers.Accounts.login/3
      # Channel connection is stateful.
      # Authorized == true <- All subsequent documents (executed by that client).
      middleware fn resolution_struct, _ -> 
        with(
          %{value: %{user: user}} <- resolution_struct
        ) do
          %{resolution_struct | context: Map.put(resolution_struct.context, :current_user, user)}
        end
      end
    end

    field :create_board, :board do
      middleware Middleware.Authorize
      resolve &Resolvers.Boards.create_board/3
    end

    # End mutation
  end

  def middleware(middleware, %{identifier: :create_user_account}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create user account"}]
  end

  def middleware(middleware, %{identifier: :create_board}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create board"}]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  subscription do
    # subscription {
    #   newBoard {
    #     id
    #     title
    #   }
    # }
    field :new_board, :board do
      
      config fn _args, _info ->
        {:ok, topic: "*"}
      end
      
    end

    # End subscription
  end

end