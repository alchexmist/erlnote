defmodule Erlnote.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Erlnote.Repo

  alias Erlnote.Accounts.{User, Credential}

  @doc """
  User authentication.

  ## Examples

      iex> authenticate(email, valid_password)
      {:ok, %User{}}

      iex> authenticate(email, bad_password)
      {:error, "Authentication error"}

      iex> authenticate(bad_email, _password)
      {:error, "Authentication error"}

  """
  def authenticate(email, password) do
    
    with(
      (%Credential{password_hash: _digest} = target_credential) <- Repo.get_by(Credential, email: email),
      {:ok, _} <- Comeonin.Pbkdf2.check_pass(target_credential, password)
    ) do
      {:ok, get_user_by_id(target_credential.user_id)}
    else
      _ -> {:error, "Authentication error"}
    end

  end

  @doc """
  Returns the User ID.

  ## Examples

      iex> get_id(user)
      1

      iex> get_id(bad_user)
      nil

  """
  def get_id(%User{} = u) do
    u.id
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user by id.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user_by_id!(123)
      %User{}

      iex> get_user_by_id!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_by_id!(id) when is_integer(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by id.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user_by_id(123)
      %User{}

      iex> get_user_by_id(456)
      nil

  """
  def get_user_by_id(id) when is_integer(id), do: Repo.get(User, id)

  @doc """
  Gets a single user by username.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user_by_username("asm")
      %User{}

      iex> get_user_by_username!("dark side of the force")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets user's credentials from user's id.

  Returns a empty list if the user's id does not exist.

  ## Examples

      iex> get_credentials!(1)
      [%Credential{}]

      iex> get_credentials(456)
      []

  """
  def get_credentials(id) do
    case (
      l = (from u in User,
      join: t in assoc(u, :credentials),
      where: u.id == ^id,
      preload: [credentials: t])
      |> Repo.one()
    ) do
      nil -> []
      _ -> l.credentials
    end
  end

  # @doc """
  # Creates a user. (Go to seeds.exs).

  # ## Examples

  #     iex> create_user(%{field: value})
  #     {:ok, %User{}}

  #     iex> create_user(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a user. (Get user: Repo.get_by(User, username: "asm"))

  ## Examples

      iex> update_user(user, %{name: "asm_aux"})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def update_credential(%Credential{} = old_credential, %Credential{} = new_credential) do
    with email = old_credential.email,
         true <- !is_nil(email),
         lower_email = String.downcase(email),
         oldc = Repo.one(from c in Credential, where: c.email == ^lower_email),
         true <- !is_nil(oldc),
         {:ok, %Credential{}} <- Comeonin.Pbkdf2.check_pass(oldc, old_credential.password) do
      Credential.changeset(oldc, %{email: new_credential.email, password: new_credential.password})
      # Changeset's field: "action" -> Set by Ecto.Repo function
      |> Repo.update
    else
      _ -> nil
    end
  end
 
  def delete_credential(%Credential{} = credential) do
    Repo.delete(credential)
  end
  
  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
