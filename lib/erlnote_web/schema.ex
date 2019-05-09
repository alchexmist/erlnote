defmodule ErlnoteWeb.Schema do
    use Absinthe.Schema

    alias Erlnote.{Repo, Accounts}

    query do
      @desc "The list of available users in the system"
      field :users, list_of(:user) do
        resolve fn _, _, _ -> {:ok, Accounts.list_users()} end
      end
    end

    object :user do
      field :id, :id
      field :name, :string
      field :username, :string  
    end
end