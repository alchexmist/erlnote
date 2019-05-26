defmodule ErlnoteWeb.Resolvers.Boards do
  
  alias Erlnote.Boards
 
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

end

