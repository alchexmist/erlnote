defmodule Erlnote.NotesTest do
  use Erlnote.DataCase

  alias Erlnote.Notes

  describe "notes" do
    alias Erlnote.Notes.{Note, NoteUser}
    alias Erlnote.Accounts
    alias Erlnote.Accounts.User

    @note_title_min_len 1
    @note_title_max_len 255
    @bad_id -1
    @valid_id 1

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

    @valid_attrs %{title: "First note", body: "En un lugar de la Mancha..."}
    @update_attrs %{title: "First note", body: "En un lugar de la Mancha...", deleted: true}
    @invalid_attrs %{deleted: "kill bit"}

    def note_fixture(attrs \\ %{}) do
      
      users = @users |> Enum.reduce([], fn u, acc -> [elem(Accounts.create_user(u), 1) | acc] end)
      notes = for {:ok, %Note{} = n} <- Enum.map(users, fn u -> Notes.create_note(Accounts.get_id(u)) end), do: n
      
      {users, notes}
    end

    defp contains_note?(_, [], acc), do: acc
    defp contains_note?(%Note{} = note, note_list, acc) when is_list(note_list) do
      [h | t] = note_list
      r = if h.id == note.id and h.user == note.user do
        [true | acc]
      else
        acc
      end
      contains_note?(note, t, r)
    end
    defp contains_note?(%Note{} = note, note_list) when is_list(note_list) do
      contains_note?(note, note_list, [])
    end

    test "create_note/1 with valid data creates a note" do
      {users, _} = note_fixture()
      [target_user | _] = users
      assert {:ok, %Note{} = note} = Notes.create_note(target_user.id)
      assert note.id != nil and note.id > 0
      note = (note |> Repo.preload(:user))
      assert note.user.id == target_user.id
      assert note.deleted == false
      title_len = String.length(note.title)
      assert note.title != nil and title_len >= @note_title_min_len and title_len <= @note_title_max_len
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@bad_id)
    end

    test "list_is_owner_notes/1 returns all user's notes" do
      {users, notes} = note_fixture()
      [target_user | _] = users 
      owner_notes = Notes.list_is_owner_notes(target_user.id)

      r = for on <- owner_notes do
        contains_note?(on, notes)
      end
      |> List.flatten
      |> Enum.count(fn x -> x == true end)
      # r = try do
      #   for n <- notes, on <- owner_notes do
      #     if n.id == on.id and n.user == on.user do
      #       throw(:found)
      #     else
      #       false
      #     end
      #   end
      # catch
      #   :found -> true
      # end

      assert r == 1
    end

    test "list_is_owner_notes/1 with invalid data returns the empty list" do
      assert Notes.list_is_owner_notes(-1) == []
    end

    test "list_is_collaborator_notes/1 with valid data returns all notes in which the user acts as a contributor" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert target_note.users == []
      assert {:ok, %NoteUser{} = note_user} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      note_list = Notes.list_is_collaborator_notes(collaborator_id)
      assert length(note_list) == 1
      [note | []] = note_list
      note = note |> Repo.preload([:users])
      assert note.id == note_user.note_id
      assert Enum.find(note.users, [], fn x -> x.id == note_user.user_id end) != []
    end

    test "list_is_collaborator_notes/1 with invalid data returns the empty list" do
      assert Notes.list_is_collaborator_notes(@bad_id) == []
    end

    test "get_note/1 returns the note with given id" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      assert Notes.get_note(target_note.id) == target_note
    end

    test "get_note/1 returns nil with invalid id" do
      assert Notes.get_note(@bad_id) == nil
    end

    test "update_note/3 with valid data updates the note" do
      {_, notes} = note_fixture()
      [note | _] = notes
      saved_id = note.id
      note = note |> Repo.preload(:user)
      assert {:ok, %Note{} = note} = Notes.update_note(note.user.id, note.id, @update_attrs)
      assert note.body == @update_attrs.body
      assert note.title == @update_attrs.title
      assert note.deleted == @update_attrs.deleted
      assert note.id == saved_id
    end

    test "update_note/3 with invalid data returns error changeset" do
      {_, notes} = note_fixture()
      [note | _] = notes
      target_note = note |> Repo.preload(:user)
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(target_note.user.id, target_note.id, @invalid_attrs)
      assert note == Notes.get_note(note.id)
    end

    test "update_note/3 with invalid note_id returns error tuple" do
      assert {:error, _} = Notes.update_note(@valid_id, @bad_id, @valid_attrs)
    end

    test "update_note/3 with invalid user_id returns error tuple" do
      assert {:error, _} = Notes.update_note(@bad_id, @valid_id, @valid_attrs)
    end

    test "link_note_to_user/5 with valid data adds a collaborator on the note" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert target_note.users == []
      assert {:ok, %NoteUser{} = note_user} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) != []
      assert Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id) != nil
    end

    test "link_note_to_user/5 with valid data (write enabled/read disabled) adds a collaborator on the note (write enabled/read disabled)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert target_note.users == []
      assert {:ok, %NoteUser{} = note_user} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, false, true)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) != []
      assert not is_nil(r = Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id))
      assert Notes.can_write?(r.user_id, r.note_id) == true
      assert Notes.can_read?(r.user_id, r.note_id) == false
    end

    test "link_note_to_user/5 with valid data (write disabled/read enabled) adds a collaborator on the note (write disabled/read enabled)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert target_note.users == []
      assert {:ok, %NoteUser{} = note_user} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, false)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) != []
      assert not is_nil(r = Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id))
      assert Notes.can_write?(r.user_id, r.note_id) == false
      assert Notes.can_read?(r.user_id, r.note_id) == true
    end

    test "link_note_to_user/5 with invalid owner ID returns permission denied error" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert target_note.users == []
      assert {:error, "Permission denied."} = Notes.link_note_to_user(@bad_id, target_note.id, collaborator_id, true, true)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) == []
      assert Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id) == nil
    end

    test "link_note_to_user/5 with invalid note ID returns a error" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert target_note.users == []
      assert {:error, "User ID or note ID not found."} = Notes.link_note_to_user(target_note.user.id, @bad_id, collaborator_id, true, true)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) == []
      assert Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id) == nil
    end

    test "link_note_to_user/5 with invalid user ID returns a error" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = @bad_id

      assert target_note.users == []
      assert {:error, "User ID or note ID not found."} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) == []
      assert Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id) == nil
    end

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
