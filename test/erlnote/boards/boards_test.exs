defmodule Erlnote.BoardsTest do
  use Erlnote.DataCase

  alias Erlnote.Boards

  describe "boards" do
    alias Erlnote.Boards.{Board, BoardUser}
    alias Erlnote.Accounts
  
    @board_title_min_len 1
    @board_title_max_len 255
    @bad_id -1

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
    @invalid_attrs %{deleted: "kill bit", text: nil, title: nil}
    @nil_attrs %{deleted: nil, text: nil, title: nil}

    def board_fixture(_attrs \\ %{}) do
      users = @users |> Enum.reduce([], fn u, acc -> [elem(Accounts.create_user(u), 1) | acc] end)
      boards = for {:ok, %Board{} = b} <- Enum.map(users, fn u -> Boards.create_board(Accounts.get_id(u)) end) do
        b
      end

      {users, boards}
    end

    defp contains_board?(_, [], acc), do: acc
    defp contains_board?(%Board{} = board, board_list, acc) when is_list(board_list) do
      [%Board{} = h | t] = board_list
      h = h |> Repo.preload(:user)
      board= board |> Repo.preload(:user)
      r = if h.id == board.id and h.user == board.user do
        [true | acc]
      else
        acc
      end
      contains_board?(board, t, r)
    end
    defp contains_board?(%Board{} = board, board_list) when is_list(board_list) do
      contains_board?(board, board_list, [])
    end

    test "create_board/1 with valid data creates a board" do
      {users, _} = board_fixture()
      [target_user | _] = users

      assert {:ok, %Board{} = board} = Boards.create_board(target_user.id)
      assert not is_nil(board.id) and board.id > 0
      assert (from b in assoc(target_user, :owner_boards), where: b.id == ^board.id) |> Repo.one == board
      board = board |> Repo.preload(:user)
      assert board.user.id == target_user.id
      assert board.deleted == false
      assert not is_nil(board.title)
      title_len = String.length(board.title)
      assert title_len >= @board_title_min_len and title_len <= @board_title_max_len
    end

    test "create_board/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Boards.create_board(@bad_id)
    end

    test "list_is_owner_boards/1 returns all user's boards" do
      {users, boards} = board_fixture()
      [target_user | _] = users 
      owner_boards = Boards.list_is_owner_boards(target_user.id)

      r = for ob <- owner_boards do
        contains_board?(ob, boards)
      end
      |> List.flatten
      |> Enum.count(fn x -> x == true end)

      assert r == 1
    end

    test "list_is_owner_boards/1 with invalid data returns the empty list" do
      assert Boards.list_is_owner_boards(@bad_id) == []
    end

    test "list_is_contributor_boards/1 with valid data returns all boards in which the user acts as a contributor" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = Repo.preload(target_board, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_board.user.id end).id

      assert target_board.users == []
      assert {:ok, %BoardUser{} = board_user} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id)
      board_list = Boards.list_is_contributor_boards(contributor_id)
      assert length(board_list) == 1
      [board | []] = board_list
      board = board |> Repo.preload([:users], force: true)
      assert board.id == target_board.id
      assert board.id == board_user.board_id
      assert Enum.find(board.users, [], fn x -> x.id == board_user.user_id end) != []
    end

    test "list_is_contributor_boards/1 with invalid data returns the empty list" do
      assert Boards.list_is_contributor_boards(@bad_id) == []
    end

    test "get_board/1 returns the board with given id" do
      {_, boards} = board_fixture()
      [target_board | _] = boards
      assert Boards.get_board(target_board.id) == target_board
    end

    test "get_board/1 returns nil with invalid id" do
      assert is_nil(Boards.get_board(@bad_id))
    end

    test "update_board/3 with valid data updates the board" do
      {_, boards} = board_fixture()
      [board | _] = boards
      board = board |> Repo.preload(:user)
      assert {:ok, %Board{} = b} = Boards.update_board(board.user.id, board.id, @update_attrs)
      assert b.text == @update_attrs.text
      assert b.title == @update_attrs.title
      assert b.deleted == @update_attrs.deleted
      assert b.id == board.id
    end

    test "update_board/3 with invalid data returns error changeset" do
      {_, boards} = board_fixture()
      [board | _] = boards
      target_board = board |> Repo.preload(:user)
      assert {:error, %Ecto.Changeset{}} = Boards.update_board(target_board.user.id, target_board.id, @invalid_attrs)
      assert board == Boards.get_board(board.id)
    end

    test "update_board/3 with invalid data (nil) returns error changeset" do
      {_, boards} = board_fixture()
      [board | _] = boards
      target_board = board |> Repo.preload(:user)
      assert {:error, %Ecto.Changeset{}} = Boards.update_board(target_board.user.id, target_board.id, @nil_attrs)
      assert board == Boards.get_board(board.id)
    end

    test "update_board/3 with invalid board_id returns error tuple" do
      {users, _} = board_fixture()
      [user | _] = users
      assert {:error, _} = Boards.update_board(user.id, @bad_id, @valid_attrs)
    end

    test "update_board/3 with invalid user_id returns error tuple" do
      {_, boards} = board_fixture()
      [board | _] = boards
      assert {:error, _} = Boards.update_board(@bad_id, board.id, @valid_attrs)
    end

    test "delete_board/2 with user ID == owner ID and contributors == [] deletes board" do
      {_, boards} = board_fixture()
      [target_board | _] = boards
      target_board = Repo.preload(target_board, :user)
      
      assert {:ok, %Board{} = b} = Boards.delete_board(target_board, target_board.user.id)
      assert target_board.id == b.id
      assert Repo.all(from b in Board, where: b.id == ^target_board.id) == []
    end

    test "delete_board/2 with user ID == owner ID and contributors != [] keeps the board and sets up deleted as true" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = Repo.preload(target_board, :user)
      contributor_id = Enum.find(users, fn c -> c.id != target_board.user.id end).id
      
      {:ok, %BoardUser{}} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id)

      assert target_board.deleted == false
      assert {:ok, %Board{} = r} = Boards.delete_board(target_board, target_board.user.id)
      assert r.id == target_board.id and r.deleted == true
      assert [updated_board | []] = Repo.all(from b in Board, where: b.id == ^target_board.id)
      assert updated_board.deleted == true
    end

    test "delete_board/2 with user ID == contributor ID and contributors == [contributor] and owner == unowned deletes board" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = Repo.preload(target_board, :user)
      contributor_id = Enum.find(users, fn c -> c.id != target_board.user.id end).id
      
      {:ok, %BoardUser{}} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id)

      {:ok, %Board{}} = Boards.delete_board(target_board, target_board.user.id)
      [updated_board | []] = Repo.all(from b in Board, where: b.id == ^target_board.id)
      assert updated_board.deleted == true
      {:ok, %Board{} = b} = Boards.delete_board(updated_board, contributor_id)
      assert target_board.id == b.id
      assert Repo.all(from b in Board, where: b.id == ^target_board.id) == []
      assert Repo.all(from bu in BoardUser, where: bu.board_id == ^target_board.id) == []
    end

    test "delete_board/2 with user ID == contributor ID and contributors == [contributor0, contributor1] and owner == unowned keeps the board" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = Repo.preload(target_board, :user)
      unique_users = Enum.uniq_by(users, fn user -> user.id end) |> Enum.reject(fn y -> y.id == target_board.user.id end)
      [contributor | contributors] = unique_users
      [contributor2 | _] = contributors
      contributor_id = contributor.id
      contributor_id2 = contributor2.id

      {:ok, %BoardUser{}} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id)
      {:ok, %BoardUser{}} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id2)
      
      {:ok, %Board{}} = Boards.delete_board(target_board, target_board.user.id)
      [updated_board | []] = Repo.all(from b in Board, where: b.id == ^target_board.id)
      assert updated_board.deleted == true

      {:ok, %Board{} = b} = Boards.delete_board(updated_board, contributor_id)
      assert target_board.id == b.id
      assert length(b.users) > 0
      assert is_nil(Enum.find(b.users, fn u -> u.id == contributor_id end))
      assert [hd | []] = Repo.all(from b in Board, where: b.id == ^target_board.id)
      assert [hd | []] = Repo.all(from bu in BoardUser, where: bu.board_id == ^target_board.id and bu.user_id == ^contributor_id2)
      assert [] = Repo.all(from bu in BoardUser, where: bu.board_id == ^target_board.id and bu.user_id == ^contributor_id)
    end

    test "change_board/1 returns a board changeset" do
      {_, boards} = board_fixture()
      assert %Ecto.Changeset{} = Boards.change_board(List.first(boards))
    end

    test "link_board_to_user/3 with valid data adds a contributor on the board" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = target_board |> Repo.preload([:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_board.user.id end).id

      assert target_board.users == []
      assert {:ok, %BoardUser{} = board_user} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id)
      assert board_user.board_id == target_board.id and board_user.user_id == contributor_id
      assert Enum.find(Boards.list_is_contributor_boards(contributor_id), [], fn x -> x.id == target_board.id end) != []
      assert not is_nil(Repo.one(from bu in BoardUser, where: bu.user_id == ^contributor_id and bu.board_id == ^target_board.id))
    end

    test "link_board_to_user/3 with invalid owner ID returns permission denied error" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = target_board |> Repo.preload([:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_board.user.id end).id

      assert target_board.users == []
      assert {:error, "Permission denied."} = Boards.link_board_to_user(@bad_id, target_board.id, contributor_id)
      assert Enum.find(Boards.list_is_contributor_boards(contributor_id), [], fn x -> x.id == target_board.id end) == []
      assert is_nil(Repo.one(from bu in BoardUser, where: bu.user_id == ^contributor_id and bu.board_id == ^target_board.id))
    end    

    test "link_board_to_user/3 with invalid board ID returns a error" do
      {users, boards} = board_fixture()
      [target_board | _] = boards
      target_board = target_board |> Repo.preload([:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_board.user.id end).id

      assert target_board.users == []
      assert {:error, "User ID or board ID not found."} = Boards.link_board_to_user(target_board.user.id, @bad_id, contributor_id)
      assert Enum.find(Boards.list_is_contributor_boards(contributor_id), [], fn x -> x.id == target_board.id end) == []
      assert is_nil(Repo.one(from bu in BoardUser, where: bu.user_id == ^contributor_id and bu.board_id == ^target_board.id))
    end

    test "link_board_to_user/3 with invalid user ID returns a error" do
      {_, boards} = board_fixture()
      [target_board | _] = boards
      target_board = target_board |> Repo.preload([:user, :users])
      contributor_id = @bad_id

      assert target_board.users == []
      assert {:error, "User ID or board ID not found."} = Boards.link_board_to_user(target_board.user.id, target_board.id, contributor_id)
      assert Enum.find(Boards.list_is_contributor_boards(contributor_id), [], fn x -> x.id == target_board.id end) == []
      assert is_nil(Repo.one(from bu in BoardUser, where: bu.user_id == ^contributor_id and bu.board_id == ^target_board.id))
    end

  end

end