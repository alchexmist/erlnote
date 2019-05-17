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
      middleware Middleware.ChangesetErrors, "Could not create user account"
    end
  end

end