defmodule Erlnote.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset


  schema "notes" do
    field :body, :string
    field :title, :string
    #field :user_id, :id
    belongs_to :user, Erlnote.Accounts.User
    #field :notepad_id, :id
    belongs_to :notepad, Erlnote.Notes.Notepad

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
  end
end
