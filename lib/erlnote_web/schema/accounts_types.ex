defmodule ErlnoteWeb.Schema.AccountsTypes do
  use Absinthe.Schema.Notation

  alias ErlnoteWeb.Resolvers
  
  object :credential do
    field :email, :string
    field :password_hash, :string
  end

  # object :user do
  #   field :id, :id
  #   field :name, :string
  #   field :username, :string
  #   field :credentials, list_of(:credential)  
  # end

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

  input_object :user_credential_input do
    field :email, non_null(:string)
    field :password, non_null(:string)
  end
  # You can't use object type for user input; you need to create input object type.
  # userAccount es un alias para createUserAccount en la respuesta.
  # mutation CreateUserAccount($accountData: UserAccountInput!) {
  #   userAccount: createUserAccount(input: $accountData) {
  #     id
  #     name
  #     username
  #     credentials {
  #       email
  #       password_hash
  #     }
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "accountData": {
  #     "username": "whitehat",
  #     "name": "White Hat",
  #     "credentials": [
  #       {
  #         "password": "12345678910",
  #         "email": "whitehat@example.com"
  #       }
  #     ]
  #   }
  # }
  input_object :user_account_input do
    field :name, non_null(:string)
    field :username, non_null(:string)
    field :credentials, non_null(list_of(:user_credential_input))
    # field :email, non_null(:string)
    # field :password, non_null(:string)
  end

  object :session do
    field :token, :string
    field :user, :user
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