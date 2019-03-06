defmodule Erlnote.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :state, :string, default: "INPROGRESS", null: false
      add :description, :text
      add :start_datetime, :utc_datetime
      add :end_datetime, :utc_datetime
      add :priority, :string, default: "NORMAL", null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

  end
end
