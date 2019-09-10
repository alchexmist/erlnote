defmodule Erlnote.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Boards.{Board, BoardUser}
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User

  # @doc """
  # Returns the list of boards.

  # ## Examples

  #     iex> list_boards()
  #     [%Board{}, ...]

  # """
  # def list_boards do
  #   Repo.all(Board)
  # end

  @doc """
  Returns the list of boards. Board owner == User ID and board.deleted == false.

  ## Examples

      iex> list_is_owner_boards(1)
      [%Board{}]

      iex> list_is_owner_boards(-1)
      []

  """
  def list_is_owner_boards(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> Repo.all(from b in assoc(user, :owner_boards), where: b.deleted == false)
    end
    # with(
    #   user = Accounts.get_user_by_id(user_id),
    #   true <- !is_nil(user),
    #   user = Repo.preload(user, :owner_boards)
    # ) do
    #   user.owner_boards
    # else
    #   _ -> nil
    # end
  end

  @doc """
  Returns the list of boards. is_contributor? == User ID.

  ## Examples

      iex> list_is_contributor_boards(1)
      [%Board{}]

      iex> list_is_contributor_boards(-1)
      []

  """
  def list_is_contributor_boards(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> []
      _ -> (from b in assoc(user, :boards)) |> Repo.all
    end
    # case user = Accounts.get_user_by_id(user_id) do
    #   nil -> []
    #   _ -> (user |> Repo.preload(:boards)).boards
    # end
  end

  # @doc """
  # Gets a single board.

  # Raises `Ecto.NoResultsError` if the Board does not exist.

  # ## Examples

  #     iex> get_board!(123)
  #     %Board{}

  #     iex> get_board!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # def get_board!(id) when is_integer(id), do: Repo.get!(Board, id)

   @doc """
  Gets a single board.

  Returns nil if the Board does not exist.

  ## Examples

      iex> get_board(1)
      %Board{}

      iex> get_board(456)
      nil

  """
  def get_board(id) when is_integer(id) do
    Repo.one(from b in Board, where: b.id == ^id and b.deleted == false)
  end

  def get_board_include_deleted(id) when is_integer(id) do
    Repo.one(from b in Board, where: b.id == ^id)
  end

  def get_access_info(user_id, board_id) when is_integer(user_id) and is_integer(board_id) do
    case  board = get_board(board_id) do
      nil -> {:error, "invalid data"}
      _ ->
        cond do
          board.owner == user_id or not is_nil(Repo.one(from u in assoc(board, :users), where: u.id == ^user_id)) ->
            {:ok, %{board_id: board.id, owner_id: board.owner, user_id: user_id, can_read: true, can_write: true}}
          true ->
            {:error, "unauthorized"}
        end
    end

  end

  @doc """
  Creates a empty board. Board owner == User ID.

  ## Examples

      iex> create_board(1)
      {:ok, %Board{}}

      iex> create_board(user_id_not_found)
      {:error, %Ecto.Changeset{}}

  """
  def create_board(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil ->
        {
          :error,
          change(%Board{}, %{user: %User{id: user_id}})
          |> add_error(:user, user_id |> Integer.to_string, additional: "User ID not found.")
        }
      _ ->
        build_assoc(user, :owner_boards)
        |> Board.create_changeset(%{text: "", title: "board-" <> Ecto.UUID.generate, deleted: false})
        |> Repo.insert()
    end
  end

  defp is_board_owner?(%Board{} = board, user_id) when is_map(board) and is_integer(user_id) do
    (board |> Repo.preload(:user)).user.id == user_id
  end

  defp is_board_user?(%Board{} = board, user_id) when is_map(board) and is_integer(user_id) do
    case (from u in assoc(board, :users), where: u.id == ^user_id) |> Repo.one do
      %User{} -> true
      _ -> false
    end
  end

  @doc """
  Updates a board.

  ## Examples

      iex> update_board(1, 1, %{field: new_value})
      {:ok, %Board{}}

      iex> update_board(1, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_board(1, -1, %{field: new_value})
      {:error, "Permission denied."}

      iex> update_board(-1, 1, %{field: new_value})
      {:error, "Permission denied."}

  """
  def update_board(user_id, board_id, attrs) when is_integer(user_id) and is_integer(board_id) and is_map(attrs) do
    with(
      board when not is_nil(board) <- get_board(board_id),
      true <- is_board_owner?(board, user_id) or is_board_user?(board, user_id)
    ) do
      update_board(board, attrs)
    else
      _ -> {:error, "Permission denied."}
    end
  end

  defp update_board(%Board{} = board, attrs) do
    board
    |> Board.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Board in the name of the user with ID == user_id.

  ## Examples

      iex> delete_board(board, user_id)
      {:ok, %Board{}}

      iex> delete_board(board, user_id)
      {:error, %Ecto.Changeset{}}

  """
  def delete_board(%Board{} = board, user_id) when is_integer(user_id) do
    board = board |> Repo.preload([:user, :users])
    cond do
      board.users == [] and user_id == board.user.id -> # Board without users (Owner)
        Repo.delete(board)
      user_id == board.user.id -> # Board with users (Owner)
        update_board(board, %{deleted: true})
      true ->
        from(r in BoardUser, where: r.user_id == ^user_id, where: r.board_id == ^board.id) |> Repo.delete_all

        if Repo.all(from(u in BoardUser, where: u.board_id == ^board.id)) == [] and board.deleted do
          Repo.delete(board)
        else
          board = Repo.preload board, :users, force: true
          {:ok, board}
        end
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking board changes.

  ## Examples

      iex> change_board(board)
      %Ecto.Changeset{source: %Board{}}

  """
  def change_board(%Board{} = board) do
    Board.update_changeset(board, %{})
  end

  # Para unlink usar la función delete_board.
  @doc """
  Adds user_id as a collaborator on the board.

  ## Examples

      iex> link_board_to_user(owner_id, board_id, user_id)
      {:ok, %BoardUser{}}

      iex> link_board_to_user(no_owner_id, board_id, user_id)
      {:error, "Permission denied."}

      iex> link_board_to_user(owner_id, bad_board_id, user_id)
      {:error, "User ID or board ID not found."}

      iex> link_board_to_user(owner_id, board_id, bad_user_id)
      {:error, "User ID or board ID not found."}

  """
  def link_board_to_user(owner_id, board_id, user_id) when is_integer(owner_id) and is_integer(board_id) and is_integer(user_id) do

    with(
      user when not is_nil(user) <- Accounts.get_user_by_id(user_id),
      board when not is_nil(board) <- Repo.preload(get_board(board_id), :user),
      true <- board.user.id == owner_id
    ) do
      cond do
        board.user.id == user_id -> {:ok, "linked"}
        true ->
          Repo.insert(
            BoardUser.changeset(%BoardUser{}, %{board_id: board.id, user_id: user.id})
          )
          # Return {:ok, _} o {:error, changeset}
      end
    else
      nil -> {:error, "User ID or board ID not found."}
      false -> {:error, "Permission denied."}
    end
  end

  # def link_board_to_user(board_id, user_id) when is_integer(board_id) and is_integer(user_id) do
  #     user = Accounts.get_user_by_id(user_id)
  #     board = get_board(board_id)
  #     cond do
  #       is_nil(user) or is_nil(board) -> {:error, "user ID or board ID not found."}
  #       (board |> Repo.preload(:user)).user.id == user_id -> {:ok, "linked"}
  #       true ->
  #         Repo.insert(
  #           BoardUser.changeset(%BoardUser{}, %{board_id: board.id, user_id: user.id})
  #         )
  #         # Return {:ok, _} o {:error, changeset}
  #     end
  #   end
end
