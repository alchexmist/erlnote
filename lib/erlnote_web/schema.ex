defmodule ErlnoteWeb.Schema do
  use Absinthe.Schema

  import_types __MODULE__.AccountsTypes

  alias ErlnoteWeb.Resolvers
  alias ErlnoteWeb.Schema.Middleware

  query do
    import_fields :accounts_queries
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
    end

    # End mutation
  end

  def middleware(middleware, %{identifier: :create_user_account}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create user account"}]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

end