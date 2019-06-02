defmodule ErlnoteWeb.Schema do
  use Absinthe.Schema

  import_types __MODULE__.AccountsTypes
  import_types __MODULE__.BoardsTypes
  import_types __MODULE__.NotesTypes
  import_types __MODULE__.NotepadsTypes
  import_types __MODULE__.TagsTypes
  import_types __MODULE__.TasklistsTypes

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
    field :notepads, list_of(:notepad)
    field :owner_tasklists, list_of(:tasklist)
  end

  object :msg do
    field :msg, non_null(:string)
  end

  interface :accessible_entity do
    field :owner_id, non_null(:id)
    field :user_id, non_null(:id)
    field :can_read, :boolean
    field :can_write, :boolean
    resolve_type fn
      %{note_id: _}, _ -> :note_access_info
      %{tasklist_id: _}, _ -> :tasklist_access_info
      %{board_id: _}, _ -> :board_access_info
      _, _ -> nil
    end
  end

  object :note_access_info do
    field :note_id, non_null(:id)
    field :owner_id, non_null(:id)
    field :user_id, non_null(:id)
    field :can_read, :boolean
    field :can_write, :boolean

    interface :accessible_entity
  end
  
  object :tasklist_access_info do
    field :tasklist_id, non_null(:id)
    field :owner_id, non_null(:id)
    field :user_id, non_null(:id)
    field :can_read, :boolean
    field :can_write, :boolean

    interface :accessible_entity
  end

  object :board_access_info do
    field :board_id, non_null(:id)
    field :owner_id, non_null(:id)
    field :user_id, non_null(:id)
    field :can_read, :boolean
    field :can_write, :boolean

    interface :accessible_entity
  end

  enum :access_info_entity_type do
    value :board
    value :tasklist
    value :note
  end

  query do
    import_fields :accounts_queries

    field :me, :user do
      middleware Middleware.Authorize
      resolve &Resolvers.Accounts.me/3
    end

    # query {
    #   getAccessInfo(entityId: "1", entityType: NOTE) {
    #     ... on NoteAccessInfo {
    #       ownerId
    #       userId
    #       canRead
    #       canWrite
    #       noteId
    #     }
    #   }
    # }
    # query {
    #   getAccessInfo(entityId: "2", entityType: BOARD) {
    #     ... on BoardAccessInfo {
    #       ownerId
    #       userId
    #       canRead
    #       canWrite
    #       boardId
    #     }
    #   }
    # }
    # query {
    #   getAccessInfo(entityId: "1", entityType: TASKLIST) {
    #     ... on TasklistAccessInfo {
    #       ownerId
    #       userId
    #       canRead
    #       canWrite
    #       tasklistId
    #     }
    #   }
    # }
    field :get_access_info, :accessible_entity do
      arg :entity_type, non_null(:access_info_entity_type)
      arg :entity_id, non_null(:id)
      middleware Middleware.Authorize
      resolve fn _, %{entity_type: et, entity_id: eid}, %{context: %{current_user: %{id: user_id}}} ->
        with(
          {eid, _} <- Integer.parse(eid)
        ) do
          case et do
            :note -> Erlnote.Notes.get_access_info(user_id, eid)
            :board -> Erlnote.Boards.get_access_info(user_id, eid)
            :tasklist -> Erlnote.Tasks.get_access_info(user_id, eid)
          end
        else
          _ -> {:error, "Invalid data"}
        end  
      end
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

    field :update_note_access, :accessible_entity do
      arg :input, non_null(:update_note_access_input)
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.update_note_access/3
    end

    field :link_tag_to_note, :msg do
      arg :note_id, non_null(:id)
      arg :tag_name, non_null(:string)
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.link_tag/3
    end

    field :remove_tag_from_note, :msg do
      arg :note_id, non_null(:id)
      arg :tag_name, non_null(:string)
      middleware Middleware.Authorize
      resolve &Resolvers.Notes.remove_tag/3
    end

    field :create_notepad, :notepad do
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.create_notepad/3
    end

    field :update_notepad, :notepad do
      arg :notepad_id, non_null(:id)
      arg :new_name, non_null(:string)
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.update_notepad/3
    end

    field :add_note_to_notepad, :note do
      arg :note_id, non_null(:id)
      arg :notepad_id, non_null(:id)
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.add_note/3
    end

    field :delete_note_from_notepad, :note do
      arg :note_id, non_null(:id)
      arg :notepad_id, non_null(:id)
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.delete_note/3
    end

    field :link_tag_to_notepad, :msg do
      arg :notepad_id, non_null(:id)
      arg :tag_name, non_null(:string)
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.link_tag/3
    end

    field :remove_tag_from_notepad, :msg do
      arg :notepad_id, non_null(:id)
      arg :tag_name, non_null(:string)
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.remove_tag/3
    end

    field :delete_notepad, :notepad do
      arg :notepad_id, non_null(:id)
      middleware Middleware.Authorize
      resolve &Resolvers.Notepads.delete_notepad/3
    end

    field :create_tasklist, :tasklist do
      middleware Middleware.Authorize
      resolve &Resolvers.Tasklists.create_tasklist/3
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

  def middleware(middleware, %{identifier: :update_note_access}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not update note"}]
  end

  def middleware(middleware, %{identifier: :link_tag_to_note}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not link tag to note"}]
  end

  def middleware(middleware, %{identifier: :remove_tag_from_note}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not remove tag from note"}]
  end

  def middleware(middleware, %{identifier: :create_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create notepad"}]
  end

  def middleware(middleware, %{identifier: :update_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not update notepad"}]
  end

  def middleware(middleware, %{identifier: :add_note_to_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not add note to notepad"}]
  end

  def middleware(middleware, %{identifier: :delete_note_from_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not add note to notepad"}]
  end

  def middleware(middleware, %{identifier: :link_tag_to_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not link tag to notepad"}]
  end

  def middleware(middleware, %{identifier: :remove_tag_from_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not remove tag from notepad"}]
  end

  def middleware(middleware, %{identifier: :delete_notepad}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not delete notepad"}]
  end

  def middleware(middleware, %{identifier: :create_tasklist}, %{identifier: :mutation}) do
    middleware ++ [{Middleware.ChangesetErrors, "Could not create tasklist"}]
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