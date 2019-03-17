defmodule Erlnote.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto
  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Boards.{Board, BoardUser}
  alias Erlnote.Accounts
  alias Erlnote.Accounts.User

  @doc """
  Returns the list of boards.

  ## Examples

      iex> list_boards()
      [%Board{}, ...]

  """
  def list_boards do
    Repo.all(Board)
  end

  def list_is_owner_boards(user_id) when is_integer(user_id) do
    with(
      user = Accounts.get_user_by_id(user_id),
      true <- !is_nil(user),
      user = Repo.preload(user, :owner_boards)
    ) do
      user.owner_boards
    else
      _ -> nil
    end
  end

  def list_is_contributor_boards(user_id) when is_integer(user_id) do
    # Falta la implementación.
    :ok  
  end

  @doc """
  Gets a single board.

  Raises `Ecto.NoResultsError` if the Board does not exist.

  ## Examples

      iex> get_board!(123)
      %Board{}

      iex> get_board!(456)
      ** (Ecto.NoResultsError)

  """
  def get_board!(id), do: Repo.get!(Board, id)

   @doc """
  Gets a single board.

  Returns nil if the Board does not exist.

  ## Examples

      iex> get_board(1)
      %Board{}

      iex> get_board(456)
      ** (Ecto.NoResultsError)

  """
  def get_board(id), do: Repo.get(Board, id)

  @doc """
  Creates a board.

  ## Examples

      iex> create_board(1)
      {:ok, %Board{}}

      iex> create_board(user_id_not_found)
      {:error, "User ID not found."}

  """
  def create_board(user_id) when is_integer(user_id) do
    case user = Accounts.get_user_by_id(user_id) do
      nil -> {:error, "User ID not found."}
      _ ->
        build_assoc(user, :owner_boards)
        |> Board.create_changeset(%{text: "", title: "board-" <> Ecto.UUID.generate, deleted: false})
        |> Repo.insert()
    end
  end

  @doc """
  Updates a board.

  ## Examples

      iex> update_board(board, %{field: new_value})
      {:ok, %Board{}}

      iex> update_board(board, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_board(%Board{} = board, attrs) do
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
    case board_users = Repo.preload(board, :users) do
      nil -> {:error, %Ecto.Changeset{}}
      _ ->
        IO.inspect(board_users.users)
        cond do
          board_users.users == [] and user_id == board.owner ->
            Repo.delete(board)
          user_id == board.owner ->
            update_board(board, %{deleted: true})
          true ->
            from(r in BoardUser, where: r.user_id == ^user_id) |> Repo.delete_all
            if Repo.all(from(u in BoardUser, where: u.board_id == ^board.id)) == [] and board.deleted do
              Repo.delete(board)
            end
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
    Board.changeset(board, %{})
  end
end
