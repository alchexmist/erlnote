defmodule Erlnote.Repo.Migrations.FixNotesUsers do
  use Ecto.Migration

  # The default value in migration is used to set
  # the value for existing rows. The default value
  # in the model is the one used when you are inserting
  # new things.
  def change do
    alter table(:notes_users, primary_key: false) do
      add :can_read, :boolean, default: true
      add :can_write, :boolean, default: true
    end
  end
end
