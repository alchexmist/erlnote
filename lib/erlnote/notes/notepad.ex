defmodule Erlnote.Notes.Notepad do
  use Ecto.Schema
  import Ecto.Changeset


  schema "notepads" do
    field :name, :string
    #field :user_id, :id
    belongs_to :user, Erlnote.Accounts.User
    

    timestamps()
  end

  @doc false
  def changeset(notepad, attrs) do
    notepad
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
