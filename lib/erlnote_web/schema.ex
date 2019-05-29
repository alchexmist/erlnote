defmodule ErlnoteWeb.Schema do
  use Absinthe.Schema

  import_types __MODULE__.AccountsTypes
  import_types __MODULE__.BoardsTypes
  import_types __MODULE__.NotesTypes

  alias ErlnoteWeb.Resolvers
  alias ErlnoteWeb.Schema.Middleware

  object :user do
    field :id, :id
    field :name, :string
    field :username, :string
    field :credentials, list_of(:credential)
    field :owner_boards, list_of(:board)
    # field :boards, list_of(:board)
    field :boards, list_of(:board), name: "contributor_boards"
    field :notes, list_of(:note), name: "owner_notes"
    field :collaborator_notes, list_of(:note), name: "contributor_notes"
  end

  object :msg do
    field :msg, non_null(:string)
  end

  query do
    import_fields :accounts_queries

    field :me, :user do
      middleware Middleware.Authorize
      resolve &Resolvers.Accounts.me/3
    end

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

    field :update_board, :board do
      arg :input, non_null(:update_board_input)
      middleware Middleware.Authorize
      resolve &Resolvers.Boards.update_board/3
    end

    field :add_board_contributor, :msg do
      arg :filter, non_null(:add_board_contributor_filter)
      middleware Middleware.Authorize
      resolve &Resolvers.Boards.add_contributor/3
    end

    field :delete_board_user, :board do
      arg :board_id, non_null(:id)
      middleware Middleware.Authorize
      resolve &Resolvers.Boards.delete_user/3
    end

    field :create_note, :note do
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.create_note/3
    end

    field :update_note, :note do
      arg :input, non_null(:update_note_input)
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.update_note/3
    end

    field :add_note_contributor, :msg do
      arg :filter, non_null(:add_note_contributor_filter)
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.add_contributor/3
    end

    field :delete_note_user, :note do
      arg :note_id, non_null(:id)
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.delete_user/3
    end

    # End mutation
  end

  def middleware(middleware, %{identifier: :create_user_account}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create user account"}]
  end

  def middleware(middleware, %{identifier: :create_board}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create board"}]
  end

  def middleware(middleware, %{identifier: :update_board}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not update board"}]
  end

  def middleware(middleware, %{identifier: :add_board_contributor}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not add board contributor"}]
  end

  def middleware(middleware, %{identifier: :delete_board_user}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not delete board user"}]
  end

  def middleware(middleware, %{identifier: :create_note}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create note"}]
  end

  def middleware(middleware, %{identifier: :update_note}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not update note"}]
  end

  def middleware(middleware, %{identifier: :add_note_contributor}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not add note contributor"}]
  end

  def middleware(middleware, %{identifier: :delete_note_user}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not delete note user"}]
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

    # subscription {
    #   boardUpdated(boardId: "2") {
    #     id
    #     title
    #     text
    #   }
    # }
    field :board_updated, :board do
      arg :board_id, non_null(:id)

      config fn args, _context -> {:ok, topic: "board#{args.board_id}:updates"} end

      trigger :update_board, topic: fn board -> "board#{board.id}:updates" end
    end

    # End subscription
  end

end