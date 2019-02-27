defmodule Erlnote.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Accounts.Credential

  schema "users" do
    field :name, :string
    field :username, :string
    has_one :credential, Credential

    timestamps()
  end

  @doc false
  def registration_changeset(user, params) do
    user
    |> changeset(params)
    |> cast_assoc(:credential, with: &Credential.changeset/2, required: true)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:username, min: 1, max: 50)
    |> unique_constraint(:username)
  end
end
