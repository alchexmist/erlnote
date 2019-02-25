defmodule Erlnote.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    field :name, :string
    field :username, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username])
    |> validate_required([:name, :username])
    |> validate_length(:name, min:1, max: 255)
    |> validate_length(:username, min: 1, max: 50)
    |> unique_constraint(:username)
  end
end
