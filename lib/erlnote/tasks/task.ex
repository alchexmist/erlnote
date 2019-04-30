defmodule Erlnote.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias Erlnote.Tasks.Tasklist

  @task_state  ~w[INPROGRESS FINISHED]
  @task_priority  ~w[LOW NORMAL HIGH]
  @max_len_name  255
  @min_len_name 1

  schema "tasks" do
    field :description, :string
    field :end_datetime, :utc_datetime
    field :name, :string
    field :priority, :string, default: "NORMAL"
    field :start_datetime, :utc_datetime
    field :state, :string, default: "INPROGRESS"
    belongs_to :tasklist, Tasklist, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:state, :description, :start_datetime, :end_datetime, :priority, :name, :id])
    |> validate_required([:state, :priority, :name, :id])
    |> validate_length(:name, min: @min_len_name, max: @max_len_name)
    |> validate_inclusion(:state, @task_state)
    |> validate_inclusion(:priority, @task_priority)
    |> validate_end_date_gt_start_date()
  end

  @doc false
  def create_changeset(task, attrs) do
    task
    |> cast(attrs, [:state, :description, :start_datetime, :end_datetime, :priority, :name, :id])
    |> validate_required([:state, :priority, :name])
    |> validate_length(:name, min: @min_len_name, max: @max_len_name)
    |> validate_inclusion(:state, @task_state)
    |> validate_inclusion(:priority, @task_priority)
    |> validate_end_date_gt_start_date()
  end

  @doc false
  defp validate_end_date_gt_start_date(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{start_datetime: _start_dt}} ->
        start_date_gt_end_date(changeset)
      %Ecto.Changeset{valid?: true, changes: %{end_datetime: _end_dt}} ->
        start_date_gt_end_date(changeset)
      _ ->
        changeset
    end  
  end

  @doc false
  defp start_date_gt_end_date(changeset) do
    with(
      start_dt = get_field(changeset, :start_datetime),
      end_dt = get_field(changeset, :end_datetime),
      true <- not is_nil(start_dt) and not is_nil(end_dt),
      :gt <- DateTime.compare(start_dt, end_dt)
    ) do
      add_error(changeset, :start_datetime, "greater than end datetime")
    else
      _ -> changeset
    end
  end

end
