defmodule ErlnoteWeb.Schema do
    use Absinthe.Schema

    alias ErlnoteWeb.Resolvers

    query do
      # query {
      #   users {
      #     id
      #     name
      #     username
      #   }
      # }
      @desc "The list of available users in the system"
      field :users, list_of(:user) do
        resolve &Resolvers.Accounts.users/3
      end

      # query {
      #   user(username: "asm") {
      #     name
      #     id
      #     username
      #   }
      # }
      @desc "Get a user of the system"
      field :user, :user do
        arg :username, non_null(:string)
        resolve &Resolvers.Accounts.user/3
      end
    end

    object :user do
      field :id, :id
      field :name, :string
      field :username, :string  
    end
end