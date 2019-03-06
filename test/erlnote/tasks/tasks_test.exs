defmodule Erlnote.TasksTest do
  use Erlnote.DataCase

  alias Erlnote.Tasks

  describe "tasks" do
    alias Erlnote.Tasks.Task

    @valid_attrs %{description: "some description", end_datetime: "2010-04-17T14:00:00Z", name: "some name", priority: "some priority", start_datetime: "2010-04-17T14:00:00Z", state: "some state"}
    @update_attrs %{description: "some updated description", end_datetime: "2011-05-18T15:01:01Z", name: "some updated name", priority: "some updated priority", start_datetime: "2011-05-18T15:01:01Z", state: "some updated state"}
    @invalid_attrs %{description: nil, end_datetime: nil, name: nil, priority: nil, start_datetime: nil, state: nil}

    def task_fixture(attrs \\ %{}) do
      {:ok, task} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Tasks.create_task()

      task
    end

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tasks.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert Tasks.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      assert {:ok, %Task{} = task} = Tasks.create_task(@valid_attrs)
      assert task.description == "some description"
      assert task.end_datetime == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert task.name == "some name"
      assert task.priority == "some priority"
      assert task.start_datetime == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert task.state == "some state"
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task(@invalid_attrs)
    end

    test "update_task/2 with valid data updates the task" do
      task = task_fixture()
      assert {:ok, %Task{} = task} = Tasks.update_task(task, @update_attrs)
      assert task.description == "some updated description"
      assert task.end_datetime == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert task.name == "some updated name"
      assert task.priority == "some updated priority"
      assert task.start_datetime == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert task.state == "some updated state"
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(task, @invalid_attrs)
      assert task == Tasks.get_task!(task.id)
    end

    test "delete_task/1 deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = Tasks.delete_task(task)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(task.id) end
    end

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = Tasks.change_task(task)
    end
  end
end
