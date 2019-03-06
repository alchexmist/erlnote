defmodule Erlnote.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  schema "credentials" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    #field :user_id, :id
    belongs_to :user, Erlnote.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8, max: 255)
    |> validate_format(:email, @email_regex)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: passwd}} ->
        put_change(changeset, :password_hash, Comeonin.Pbkdf2.hashpwsalt(passwd))
        # Luego usaremos Comeonin.Pbkdf2.verify_pass(password, stored_hash)
      _ ->
        changeset
    end
  end

end
