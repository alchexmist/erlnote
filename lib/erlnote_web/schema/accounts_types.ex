defmodule ErlnoteWeb.Schema.AccountsTypes do
  use Absinthe.Schema.Notation

  alias ErlnoteWeb.Resolvers
  
  object :user do
    field :id, :id
    field :name, :string
    field :username, :string  
  end

  enum :get_user_filter_type do
    value :id #, as: "id" # Con el "as" se reciben string en lugar de atoms.
    value :username #, as: "username"
  end

  @desc "Filtering options for get user"
  input_object :get_user_filter do
    @desc "ID or USERNAME"
    field :type, non_null(:get_user_filter_type)
    @desc "String value"
    field :value, non_null(:string)
  end

  object :accounts_queries do
          # query UserList {
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

      # query UserByUsername ($term: String) { //BROKEN!!!
      #   user(username: $term) {
      #     name
      #     id
      #     username
      #   }
      # }
      # POST Request Body
      # Variables => JSON Encoded
      # “{
      #    "query"​: ​"query UserByUsername ($term: String) { user(username: $term) { name id username} }"​,
      #    "variables"​: ​"{​​\"​​term​​\"​​: ​​\"​​asm\"​​}"​
      # }”
      # query UserById{
      #   user (filter: {type: ID, value: "1"}) {
      #     name
      #     id
      #     username
      #   }
      # }
      # query UserByUsername {
      #   user (filter: {type: USERNAME, value: "asm"}) {
      #     name
      #     id
      #     username
      #   }
      # }
      @desc "Get a user of the system"
      field :user, :user do
        arg :filter, non_null(:get_user_filter)
        resolve &Resolvers.Accounts.user/3
      end
  end


end