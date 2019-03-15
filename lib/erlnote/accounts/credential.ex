defmodule Erlnote.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.User

  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  schema "credentials" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    #field :user_id, :id
    belongs_to :user, User, on_replace: :delete
    
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8, max: 255)
    |> validate_format(:email, @email_regex)
    |> email_to_lowercase()
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp email_to_lowercase(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{email: email}} ->
        put_change(changeset, :email, String.downcase(email))
      _ ->
        changeset 
    end
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: passwd}} ->
        put_change(changeset, :password_hash, Comeonin.Pbkdf2.hashpwsalt(passwd))
        # Luego usaremos Comeonin.Pbkdf2.check_pass(password)
        # Looks for password_hash field (in struct) 
      _ ->
        changeset
    end
  end

end
