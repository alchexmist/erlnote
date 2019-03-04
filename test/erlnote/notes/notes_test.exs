defmodule Erlnote.NotesTest do
  use Erlnote.DataCase

  alias Erlnote.Notes

  describe "notepads" do
    alias Erlnote.Notes.Notepad

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def notepad_fixture(attrs \\ %{}) do
      {:ok, notepad} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Notes.create_notepad()

      notepad
    end

    test "list_notepads/0 returns all notepads" do
      notepad = notepad_fixture()
      assert Notes.list_notepads() == [notepad]
    end

    test "get_notepad!/1 returns the notepad with given id" do
      notepad = notepad_fixture()
      assert Notes.get_notepad!(notepad.id) == notepad
    end

    test "create_notepad/1 with valid data creates a notepad" do
      assert {:ok, %Notepad{} = notepad} = Notes.create_notepad(@valid_attrs)
      assert notepad.name == "some name"
    end

    test "create_notepad/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_notepad(@invalid_attrs)
    end

    test "update_notepad/2 with valid data updates the notepad" do
      notepad = notepad_fixture()
      assert {:ok, %Notepad{} = notepad} = Notes.update_notepad(notepad, @update_attrs)
      assert notepad.name == "some updated name"
    end

    test "update_notepad/2 with invalid data returns error changeset" do
      notepad = notepad_fixture()
      assert {:error, %Ecto.Changeset{}} = Notes.update_notepad(notepad, @invalid_attrs)
      assert notepad == Notes.get_notepad!(notepad.id)
    end

    test "delete_notepad/1 deletes the notepad" do
      notepad = notepad_fixture()
      assert {:ok, %Notepad{}} = Notes.delete_notepad(notepad)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_notepad!(notepad.id) end
    end

    test "change_notepad/1 returns a notepad changeset" do
      notepad = notepad_fixture()
      assert %Ecto.Changeset{} = Notes.change_notepad(notepad)
    end
  end
end
