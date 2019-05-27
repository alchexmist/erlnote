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
      Boards.update_board(user_id, board_id, params)
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


end

