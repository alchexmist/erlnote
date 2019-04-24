defmodule Erlnote.BoardsTest do
  use Erlnote.DataCase

  alias Erlnote.Boards

  describe "boards" do
    alias Erlnote.Boards.{Board, BoardUser}
    alias Erlnote.Accounts
  
    @board_title_min_len 1
    @board_title_max_len 255
    @bad_id -1
    @valid_id 1

    @users [
      %{
        name: "User 1",
        username: "user1",
        credentials: [
          %{
            email: "user1@example.com",
            password: "superfreak"
          }
        ]
      },
      %{
        name: "User 2",
        username: "user2",
        credentials: [
          %{
            email: "user2@example.com",
            password: "supergeek"
          }
        ]
      },
      %{
        name: "User 3",
        username: "user3",
        credentials: [
          %{
            email: "user3@example.com",
            password: "supernerd"
          }
        ]
      }
    ]

    @valid_attrs %{deleted: false, text: "Lord of C6H6 ring!", title: "Benceno, que no tolueno!"}
    @update_attrs %{deleted: false, text: "Dimetilaliltranstransferasa", title: "Enzimas"}
    @invalid_attrs %{deleted: nil, text: nil, title: nil}

    def board_fixture(_attrs \\ %{}) do
      users = @users |> Enum.reduce([], fn u, acc -> [elem(Accounts.create_user(u), 1) | acc] end)
      boards = for {:ok, %Board{} = b} <- Enum.map(users, fn u -> Boards.create_board(Accounts.get_id(u)) end) do
        b
      end

      {users, boards}
    end

    # test "list_boards/0 returns all boards" do
    #   board = board_fixture()
    #   assert Boards.list_boards() == [board]
    # end

    # test "get_board!/1 returns the board with given id" do
    #   board = board_fixture()
    #   assert Boards.get_board!(board.id) == board
    # end

    # test "create_board/1 with valid data creates a board" do
    #   assert {:ok, %Board{} = board} = Boards.create_board(@valid_attrs)
    #   assert board.deleted == true
    #   assert board.text == "some text"
    #   assert board.title == "some title"
    # end

    # test "create_board/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Boards.create_board(@invalid_attrs)
    # end

    # test "update_board/2 with valid data updates the board" do
    #   board = board_fixture()
    #   assert {:ok, %Board{} = board} = Boards.update_board(board, @update_attrs)
    #   assert board.deleted == false
    #   assert board.text == "some updated text"
    #   assert board.title == "some updated title"
    # end

    # test "update_board/2 with invalid data returns error changeset" do
    #   board = board_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Boards.update_board(board, @invalid_attrs)
    #   assert board == Boards.get_board!(board.id)
    # end

    # test "delete_board/1 deletes the board" do
    #   board = board_fixture()
    #   assert {:ok, %Board{}} = Boards.delete_board(board)
    #   assert_raise Ecto.NoResultsError, fn -> Boards.get_board!(board.id) end
    # end

    # test "change_board/1 returns a board changeset" do
    #   board = board_fixture()
    #   assert %Ecto.Changeset{} = Boards.change_board(board)
    # end


  end
end
