defmodule ErlnoteWeb.Resolvers.Boards do
  
  alias Erlnote.Boards
  alias Erlnote.Accounts

  # mutation CreateBoard {
  #   board: createBoard {
  #     id
  #     title
  #   }
  # }
  # {
  #   "data": {
  #     "board": {
  #       "title": "board-5c3c8462-45c7-43d9-9c04-090f894f8981",
  #       "id": "5"
  #     }
  #   }
  # }
  # Valid Authentication Token: Required (HTTP Header).
  def create_board(_, _, %{context: context}) do
    # case context do
    #   %{current_user: %{id: id}} -> Boards.create_board(id)
    #   _ -> {:error, "unauthorized"}
    # end
    %{current_user: %{id: id}} = context
    case r = Boards.create_board(id) do
      {:ok, %Erlnote.Boards.Board{} = board} ->
        Absinthe.Subscription.publish(ErlnoteWeb.Endpoint, board, new_board: "*")
        r
      _ -> r
    end
  end

  # mutation UpdateBoard($boardData: UpdateBoardInput!) {
  #   board: updateBoard(input: $boardData) {
  #     id
  #     text
  #     title
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "boardData": {
  #     "id": "1",
  #     "text": "White Hat",
  #     "title": "The tower of Hercules"
  #   }
  # }
  def update_board(_, %{input: params}, %{context: context}) do
    IO.inspect params
    IO.inspect context
    with(
      %{current_user: %{id: user_id}} <- context,
      %{id: b_id} <- params,
      #{user_id, _} <- Integer.parse(u_id),
      {board_id, _} <- Integer.parse(b_id)
    ) do
      case r = Boards.update_board(user_id, board_id, params) do
        {:ok, board} -> {:ok, Map.put(Map.from_struct(board), :updated_by, user_id)}
        _ -> r
      end
    else
      _ -> {:error, "Invalid data"}
    end
  end

  # mutation AddBoardContributor($data: AddBoardContributorFilter!){
  #   addBoardContributor(filter: $data) {
  #     msg
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": {
  #     "type": "ID",
  #     "value": "2",
  #     "bid": "11"
  #   }
  # }
  # RESULT
  # {
  #   "data": {
  #     "addBoardContributor": {
  #       "msg": "ok"
  #     }
  #   }
  # }
  def add_contributor(_, %{filter: opts}, %{context: context}) do
    r = case {opts, context} do
      {%{type: :id, value: i, bid: bid}, %{current_user: %{id: owner_id}}} when is_binary(i) ->
        with(
          {i, _} <- Integer.parse(i),
          {bid, _} <- Integer.parse(bid),
          user when not is_nil(user) <- Accounts.get_user_by_id(i)
        ) do
          Boards.link_board_to_user(owner_id, bid, user.id)
        else
          _ -> {:error, "Invalid data"}
        end
      {%{type: :username, value: u, bid: bid}, %{current_user: %{id: owner_id}}} when is_binary(u) ->
        with(
          {bid, _} <- Integer.parse(bid),
          user when not is_nil(user) <- Accounts.get_user_by_username(u)
        ) do
          Boards.link_board_to_user(owner_id, bid, user.id)
        else
          _ -> {:error, "Invalid data"}
        end
    end

    case r do
      {:ok, _} -> {:ok, %{msg: "ok"}}
      _ -> r
    end
  end

  defp delete_contributor_priv(current_user_id, board_owner_id, board_id, user_id) when is_integer(current_user_id) and is_integer(board_owner_id) and is_integer(board_id) and is_integer(user_id) do
    case {current_user_id, Boards.get_board(board_id)} do
      {_, nil} -> {:error, "Invalid board ID"}
      {^board_owner_id, b} -> Boards.delete_board(b, user_id)
      {^user_id, b} -> Boards.delete_board(b, user_id)
      _ -> {:error, "Invalid data (delete_contributor_priv) current_user_id #{current_user_id} board_owner_id #{board_owner_id} board_id #{board_id} user_id #{user_id} "}
    end
  end
  
  # mutation DeleteBoardContributor($data: DeleteBoardContributorFilter!){
  #   deleteBoardContributor(filter: $data) {
  #     msg
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": {
  #     "type": "ID" o "USERNAME",
  #     "value": "2" o "pepito",
  #     "bid": "11"
  #   }
  # }
  # RESULT
  # {
  #   "data": {
  #     "deleteBoardContributor": {
  #       "msg": "ok"
  #     }
  #   }
  # }
  def delete_contributor(_, %{filter: opts}, %{context: context}) do
    r = case {opts, context} do
      {%{type: :id, value: i, bid: bid}, %{current_user: %{id: owner_id}}} when is_binary(i) ->
        with(
          {i, _} <- Integer.parse(i),
          {bid, _} <- Integer.parse(bid),
          user when not is_nil(user) <- Accounts.get_user_by_id(i),
          {:ok, %{owner_id: board_owner}} <- Boards.get_access_info(owner_id, bid)
          # {:ok, %{owner_id: board_owner}} <- Boards.get_access_info(owner_id, user.id)
        ) do

          delete_contributor_priv(owner_id, board_owner, bid, user.id)

        else
          _ -> {:error, "Invalid data"}
        end
      {%{type: :username, value: u, bid: bid}, %{current_user: %{id: owner_id}}} when is_binary(u) ->
        with(
          {bid, _} <- Integer.parse(bid),
          user when not is_nil(user) <- Accounts.get_user_by_username(u),
          {:ok, %{owner_id: board_owner}} <- Boards.get_access_info(owner_id, bid)
          # {:ok, %{owner_id: board_owner}} <- Boards.get_access_info(owner_id, user.id)
        ) do

          delete_contributor_priv(owner_id, board_owner, bid, user.id)

        else
          _ -> {:error, "Invalid data"}
        end
    end

    case r do
      {:ok, _} -> {:ok, %{msg: "ok"}}
      _ -> r
    end
  end

  # mutation DeleteBoardUser($data: ID!) {
  #   deleteBoardUser(boardId: $data) {
  #     id
  #     title
  #   }
  # }
  # QUERY VARIABLES
  # {
  #   "data": "10"
  # }
  # RESPONSE
  # {
  #   "data": {
  #     "deleteBoardUser": {
  #       "title": "board-8fed75fe-a283-4aca-bc28-29f5c393aa77",
  #       "id": "10"
  #     }
  #   }
  # }
  def delete_user(_, %{board_id: board_id}, %{context: context}) do
    with(
      {board_id, _} <- Integer.parse(board_id),
      %{current_user: %{id: user_id}} <- context,
      board when not is_nil(board) <- Boards.get_board_include_deleted(board_id)
    ) do
      Boards.delete_board(board, user_id)
    else
      _ -> 
        {:error, "Invalid data"}
    end
  end


end

