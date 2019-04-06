defmodule Erlnote.NotesTest do
  use Erlnote.DataCase

  alias Erlnote.Notes

  describe "notes" do
    alias Erlnote.Notes.Note
    alias Erlnote.Accounts
    alias Erlnote.Accounts.User

    @users [
      %{
        name: "User 1",
        username: "user1",
        credentials: [
          %{
            email: "user1@example.com",
            password: "superfreak"
          }
        ]
      },
      %{
        name: "User 2",
        username: "user2",
        credentials: [
          %{
            email: "user2@example.com",
            password: "supergeek"
          }
        ]
      },
      %{
        name: "User 3",
        username: "user3",
        credentials: [
          %{
            email: "user3@example.com",
            password: "supernerd"
          }
        ]
      }
    ]

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def note_fixture(attrs \\ %{}) do
      
      users = @users |> Enum.reduce([], fn u, acc -> [elem(Accounts.create_user(u), 1) | acc] end)
      notes = for {:ok, %Note{} = n} <- Enum.map(users, fn u -> Notes.create_note(Accounts.get_id(u)) end), do: n
      
      {users, notes}
    end

    test "list_is_owner_notes/1 returns all user's notes" do
      {users, notes} = note_fixture()
      [target_user | _] = users 
      owner_notes = Notes.list_is_owner_notes(target_user.id)

      r = for n <- notes, on <- owner_notes do
        cond do
          n.id == on.id and n.user == on.user -> true
          true -> false
        end
      end

      assert Enum.member?(r, true)
    end

    # test "get_notepad!/1 returns the notepad with given id" do
    #   notepad = notepad_fixture()
    #   assert Notes.get_notepad!(notepad.id) == notepad
    # end

    # test "create_notepad/1 with valid data creates a notepad" do
    #   assert {:ok, %Notepad{} = notepad} = Notes.create_notepad(@valid_attrs)
    #   assert notepad.name == "some name"
    # end

    # test "create_notepad/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Notes.create_notepad(@invalid_attrs)
    # end

    # test "update_notepad/2 with valid data updates the notepad" do
    #   notepad = notepad_fixture()
    #   assert {:ok, %Notepad{} = notepad} = Notes.update_notepad(notepad, @update_attrs)
    #   assert notepad.name == "some updated name"
    # end

    # test "update_notepad/2 with invalid data returns error changeset" do
    #   notepad = notepad_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Notes.update_notepad(notepad, @invalid_attrs)
    #   assert notepad == Notes.get_notepad!(notepad.id)
    # end

    # test "delete_notepad/1 deletes the notepad" do
    #   notepad = notepad_fixture()
    #   assert {:ok, %Notepad{}} = Notes.delete_notepad(notepad)
    #   assert_raise Ecto.NoResultsError, fn -> Notes.get_notepad!(notepad.id) end
    # end

    # test "change_notepad/1 returns a notepad changeset" do
    #   notepad = notepad_fixture()
    #   assert %Ecto.Changeset{} = Notes.change_notepad(notepad)
    # end
  end

  # describe "notepads" do
  #   alias Erlnote.Notes.Notepad

  #   @valid_attrs %{name: "some name"}
  #   @update_attrs %{name: "some updated name"}
  #   @invalid_attrs %{name: nil}

  #   def notepad_fixture(attrs \\ %{}) do
  #     {:ok, notepad} =
  #       attrs
  #       |> Enum.into(@valid_attrs)
  #       |> Notes.create_notepad()

  #     notepad
  #   end

  #   test "list_notepads/0 returns all notepads" do
  #     notepad = notepad_fixture()
  #     assert Notes.list_notepads() == [notepad]
  #   end

  #   test "get_notepad!/1 returns the notepad with given id" do
  #     notepad = notepad_fixture()
  #     assert Notes.get_notepad!(notepad.id) == notepad
  #   end

  #   test "create_notepad/1 with valid data creates a notepad" do
  #     assert {:ok, %Notepad{} = notepad} = Notes.create_notepad(@valid_attrs)
  #     assert notepad.name == "some name"
  #   end

  #   test "create_notepad/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Notes.create_notepad(@invalid_attrs)
  #   end

  #   test "update_notepad/2 with valid data updates the notepad" do
  #     notepad = notepad_fixture()
  #     assert {:ok, %Notepad{} = notepad} = Notes.update_notepad(notepad, @update_attrs)
  #     assert notepad.name == "some updated name"
  #   end

  #   test "update_notepad/2 with invalid data returns error changeset" do
  #     notepad = notepad_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Notes.update_notepad(notepad, @invalid_attrs)
  #     assert notepad == Notes.get_notepad!(notepad.id)
  #   end

  #   test "delete_notepad/1 deletes the notepad" do
  #     notepad = notepad_fixture()
  #     assert {:ok, %Notepad{}} = Notes.delete_notepad(notepad)
  #     assert_raise Ecto.NoResultsError, fn -> Notes.get_notepad!(notepad.id) end
  #   end

  #   test "change_notepad/1 returns a notepad changeset" do
  #     notepad = notepad_fixture()
  #     assert %Ecto.Changeset{} = Notes.change_notepad(notepad)
  #   end
  # end
end
