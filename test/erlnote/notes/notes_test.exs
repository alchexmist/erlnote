defmodule Erlnote.NotesTest do
  use Erlnote.DataCase

  alias Erlnote.Notes

  describe "notes" do
    alias Erlnote.Notes.{Note, NoteUser, NoteTag}
    alias Erlnote.Accounts
    alias Erlnote.Tags
    alias Erlnote.Tags.Tag

    @note_title_min_len 1
    @note_title_max_len 255
    @bad_id -1
    @valid_id 1
    @valid_tag_name "White hat"
    @valid_tag_name_list ~w(white_hat black_hat blue_hat)

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
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = @bad_id

      assert target_note.users == []
      assert {:error, "User ID or note ID not found."} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      assert Enum.find(Notes.list_is_collaborator_notes(collaborator_id), [], fn x -> x.id == target_note.id end) == []
      assert Repo.one(from nu in NoteUser, where: nu.user_id == ^collaborator_id and nu.note_id == ^target_note.id) == nil
    end

    test "set_can_read_from_note/3 with valid data enables/disables read permission for (contributor, note)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      {:ok, %NoteUser{} = _} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      assert Notes.can_read?(collaborator_id, target_note.id) == true
      assert {:ok, %NoteUser{}} = Notes.set_can_read_from_note(collaborator_id, target_note.id, false)
      assert Notes.can_read?(collaborator_id, target_note.id) == false
      assert {:ok, %NoteUser{}} = Notes.set_can_read_from_note(collaborator_id, target_note.id, true)
      assert Notes.can_read?(collaborator_id, target_note.id) == true
    end

    test "set_can_read_from_note/3 with invalid contributor ID returns error" do
      {_, notes} = note_fixture()
      [target_note | _] = notes

      assert {:error, _} = Notes.set_can_read_from_note(@bad_id, target_note.id, false)
    end

    test "set_can_read_from_note/3 with invalid note ID returns error" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert {:error, _} = Notes.set_can_read_from_note(collaborator_id, @bad_id, false)
    end

    test "set_can_write_to_note/3 with valid data enables/disables write permission for (contributor, note)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      {:ok, %NoteUser{}} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      assert Notes.can_write?(collaborator_id, target_note.id) == true
      assert {:ok, %NoteUser{}} = Notes.set_can_write_to_note(collaborator_id, target_note.id, false)
      assert Notes.can_write?(collaborator_id, target_note.id) == false
      assert {:ok, %NoteUser{}} = Notes.set_can_write_to_note(collaborator_id, target_note.id, true)
      assert Notes.can_write?(collaborator_id, target_note.id) == true
    end

    test "set_can_write_to_note/3 with invalid contributor ID returns error" do
      {_, notes} = note_fixture()
      [target_note | _] = notes

      assert {:error, _} = Notes.set_can_write_to_note(@bad_id, target_note.id, false)
    end

    test "set_can_write_to_note/3 with invalid note ID returns error" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert {:error, _} = Notes.set_can_write_to_note(collaborator_id, @bad_id, false)
    end

    test "can_write?/2 always returns true (owner of the note)" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user])
      
      assert Notes.can_write?(target_note.user.id, target_note.id) == true
    end

    test "can_write?/2 always returns true or false (contributor of the note)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id
      collaborator_id2 = Enum.find(users, fn u -> u.id not in [target_note.user.id, collaborator_id] end).id

      {:ok, %NoteUser{} = _} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      {:ok, %NoteUser{} = _} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id2, true, false)

      assert Notes.can_write?(collaborator_id, target_note.id) == true
      assert Notes.can_write?(collaborator_id2, target_note.id) == false
    end

    test "can_write?/2 always returns false (invalid IDs)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert Notes.can_write?(@bad_id, target_note.id) == false
      assert Notes.can_write?(collaborator_id, @bad_id) == false
    end

    test "can_read?/2 always returns true (owner of the note)" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user])
      
      assert Notes.can_read?(target_note.user.id, target_note.id) == true
    end

    test "can_read?/2 always returns true or false (contributor of the note)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id
      collaborator_id2 = Enum.find(users, fn u -> u.id not in [target_note.user.id, collaborator_id] end).id

      {:ok, %NoteUser{} = _} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id, true, true)
      {:ok, %NoteUser{} = _} = Notes.link_note_to_user(target_note.user.id, target_note.id, collaborator_id2, false, true)

      assert Notes.can_read?(collaborator_id, target_note.id) == true
      assert Notes.can_read?(collaborator_id2, target_note.id) == false
    end

    test "can_read?/2 always returns false (invalid IDs)" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user])
      collaborator_id = Enum.find(users, fn u -> u.id != target_note.user.id end).id

      assert Notes.can_read?(@bad_id, target_note.id) == false
      assert Notes.can_read?(collaborator_id, @bad_id) == false
    end

    test "link_tag_to_note/3 with valid data creates assoc(note, tag)" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :tags])
      
      assert target_note.tags == []
      assert {:ok, %NoteTag{} = nt} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert nt.note_id == target_note.id
      (%Tag{} = t) = Tags.get_tag_by_name(@valid_tag_name)
      assert nt.tag_id == t.id
      assert Repo.one(from r in assoc(target_note, :tags), where: r.id == ^t.id and r.name == ^@valid_tag_name) != nil
    end

    test "link_tag_to_note/3 with duplicated tag name does nothing" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :tags])
      
      assert target_note.tags == []
      assert {:ok, %NoteTag{} = nt} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert {:ok, msg} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert is_binary msg
      assert nt.note_id == target_note.id
      (%Tag{} = t) = Tags.get_tag_by_name(@valid_tag_name)
      assert nt.tag_id == t.id
      assert Repo.one(from r in assoc(target_note, :tags), where: r.id == ^t.id and r.name == ^@valid_tag_name) != nil
    end

    test "link_tag_to_note/3 with invalid note ID returns error" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      
      assert {:error, msg} = Notes.link_tag_to_note(@bad_id, target_note.user.id, @valid_tag_name)
    end

    test "link_tag_to_note/3 with invalid user ID returns error" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, [:user, :tags])
      
      assert target_note.tags == []
      assert {:error, msg} = Notes.link_tag_to_note(target_note.id, @bad_id, @valid_tag_name)
      assert Repo.all(from r in NoteTag, where: r.note_id == ^target_note.id and r.tag_id == ^@bad_id) == []
    end
    
    test "get_tags_from_note/1 lists all the associated tags (note with tags)" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      [tag_name_x | tail] = @valid_tag_name_list
      [tag_name_y | _] = tail

      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note.id, target_note.user.id, tag_name_x)
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note.id, target_note.user.id, tag_name_y)
      tag_list = Notes.get_tags_from_note(target_note.id)
      assert length(tag_list) == 2
      tn1 = List.first(tag_list).name
      tn2 = List.last(tag_list).name
      assert tag_name_x == tn1 or tag_name_x == tn2
      assert tag_name_y == tn1 or tag_name_y == tn2
    end

    test "get_tags_from_note/1 returns empty list (note without tags)" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :tags)
      
      assert target_note.tags == []
      assert Notes.get_tags_from_note(target_note.id) == []
    end

    test "get_tags_from_note/1 with invalid note ID returns empty list" do
      assert Notes.get_tags_from_note(@bad_id) == []
    end

    test "remove_tag_from_note/3 with valid data breaks assoc(note, tag)" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert not is_nil(Enum.find(Notes.get_tags_from_note(target_note.id), fn t -> @valid_tag_name == t.name end))
      %{remove_tag_from_note: {1, nil}, delete_tag: {:ok, %Tag{}}} = Notes.remove_tag_from_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert is_nil(Enum.find(Notes.get_tags_from_note(target_note.id), fn t -> @valid_tag_name == t.name end))
    end

    test "remove_tag_from_note/3 with valid data breaks assoc(note, tag). (tag_name_in_use_by_other_entities)" do
      {_, notes} = note_fixture()
      [target_note | other_notes] = notes
      target_note = Repo.preload(target_note, :user)
      [target_note2 | _] = other_notes
      target_note2 = Repo.preload(target_note2, :user)
      
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note2.id, target_note2.user.id, @valid_tag_name)
      assert not is_nil(Enum.find(Notes.get_tags_from_note(target_note.id), fn t -> @valid_tag_name == t.name end))
      assert not is_nil(Enum.find(Notes.get_tags_from_note(target_note2.id), fn t -> @valid_tag_name == t.name end))
      %{remove_tag_from_note: {1, nil}, delete_tag: {:error, _}} = Notes.remove_tag_from_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert is_nil(Enum.find(Notes.get_tags_from_note(target_note.id), fn t -> @valid_tag_name == t.name end))
      assert not is_nil(Enum.find(Notes.get_tags_from_note(target_note2.id), fn t -> @valid_tag_name == t.name end))
    end

    test "remove_tag_from_note/3 with invalid note ID returns error" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      
      assert {:error, _} = Notes.remove_tag_from_note(@bad_id, target_note.user.id, @valid_tag_name)
    end

    test "remove_tag_from_note/3 with invalid user ID returns error" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)
      assert not is_nil(Enum.find(Notes.get_tags_from_note(target_note.id), fn t -> @valid_tag_name == t.name end))
      {:error, _} = Notes.remove_tag_from_note(target_note.id, @bad_id, @valid_tag_name)
    end

    test "delete_note/2 with user ID == owner ID and contributors == [] deletes note" do
      {_, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(target_note.id, target_note.user.id, @valid_tag_name)

      assert {:ok, %Note{} = n} = Notes.delete_note(target_note, target_note.user.id)
      assert target_note.id == n.id
      assert Repo.all(from nt in Note, where: nt.id == ^target_note.id) == []
      assert Repo.all(from r in NoteTag, where: r.note_id == ^target_note.id) == []
    end

    test "delete_note/2 with user ID == owner ID and contributors != [] keeps the note and sets up deleted as true" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      contributor_id = Enum.find(users, fn c -> c.id != target_note.user.id end).id
      
      {:ok, %NoteUser{}} = Notes.link_note_to_user(target_note.user.id, target_note.id, contributor_id, true, true)

      assert target_note.deleted == false
      assert {:ok, %Note{}} = Notes.delete_note(target_note, target_note.user.id)
      assert [updated_note | []] = Repo.all(from nt in Note, where: nt.id == ^target_note.id)
      assert updated_note.deleted == true
    end

    test "delete_note/2 with user ID == contributor ID and contributors == [contributor] and owner == unowned deletes note" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      contributor_id = Enum.find(users, fn c -> c.id != target_note.user.id end).id
      
      {:ok, %NoteUser{}} = Notes.link_note_to_user(target_note.user.id, target_note.id, contributor_id, true, true)

      {:ok, %Note{}} = Notes.delete_note(target_note, target_note.user.id)
      [updated_note | []] = Repo.all(from nt in Note, where: nt.id == ^target_note.id)
      assert updated_note.deleted == true
      {:ok, %Note{} = nc} = Notes.delete_note(updated_note, contributor_id)
      assert target_note.id == nc.id
      assert Repo.all(from nt in Note, where: nt.id == ^target_note.id) == []
      assert Repo.all(from nu in NoteUser, where: nu.note_id == ^target_note.id) == []
    end

    test "delete_note/2 with user ID == contributor ID and contributors == [contributor0, contributor1] and owner == unowned keeps the note" do
      {users, notes} = note_fixture()
      [target_note | _] = notes
      target_note = Repo.preload(target_note, :user)
      unique_users = Enum.uniq_by(users, fn user -> user.id end) |> Enum.reject(fn y -> y.id == target_note.user.id end)
      [contributor | contributors] = unique_users
      [contributor2 | _] = contributors
      contributor_id = contributor.id
      contributor_id2 = contributor2.id

      {:ok, %NoteUser{}} = Notes.link_note_to_user(target_note.user.id, target_note.id, contributor_id, true, true)
      {:ok, %NoteUser{}} = Notes.link_note_to_user(target_note.user.id, target_note.id, contributor_id2, true, true)
      
      {:ok, %Note{}} = Notes.delete_note(target_note, target_note.user.id)
      [updated_note | []] = Repo.all(from nt in Note, where: nt.id == ^target_note.id)
      assert updated_note.deleted == true

      {:ok, %Note{} = nc} = Notes.delete_note(updated_note, contributor_id)
      assert target_note.id == nc.id
      assert length(nc.users) > 0
      assert Enum.find(nc.users, fn u -> u.id == contributor_id end) == nil
      assert [hd | []] = Repo.all(from nt in Note, where: nt.id == ^target_note.id)
      assert [hd | []] = Repo.all(from nu in NoteUser, where: nu.note_id == ^target_note.id and nu.user_id == ^contributor_id2)
      assert [] = Repo.all(from nu in NoteUser, where: nu.note_id == ^target_note.id and nu.user_id == ^contributor_id)
    end
 
  end

  describe "notepads" do
    alias Erlnote.Notes.{Notepad, Note, NoteUser, NoteTag}
    alias Erlnote.Accounts
    alias Erlnote.Tags
    alias Erlnote.Tags.Tag

    @note_title_min_len 1
    @note_title_max_len 255
    @bad_id -1
    @valid_id 1
    @valid_tag_name "White hat"
    @valid_tag_name_list ~w(white_hat black_hat blue_hat)

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

    @valid_attrs %{name: "First notepad"}
    @update_attrs %{name: "Y el bit que colmó el buffer es ..."}
    @invalid_attrs %{name: String.duplicate("Alberto", 300)}

    def notepad_fixture(attrs \\ %{}) do
      
      users = @users |> Enum.reduce([], fn u, acc -> [elem(Accounts.create_user(u), 1) | acc] end)
      notes = for {:ok, %Note{} = n} <- Enum.map(users, fn u -> Notes.create_note(Accounts.get_id(u)) end), do: n
      notepads = for {:ok, %Notepad{} = np} <- Enum.map(users, fn u -> Notes.create_notepad(Accounts.get_id(u)) end), do: np

      {users, notes, notepads}
    end
 
    test "list_notepads/1 returns all user's notepads" do
      {users, notes, notepads} = notepad_fixture()
      [target_user | _] = users
      target_user = target_user |> Repo.preload(:notepads)
      assert target_user.notepads != []

      f = fn x, acc -> MapSet.put(acc, x) end
      notepad_set = Enum.reduce(Notes.list_notepads(target_user.id), MapSet.new(), f)
      notepad_ref_set = Enum.reduce(target_user.notepads, MapSet.new(), f)
      assert MapSet.size(notepad_set) > 0 and MapSet.size(notepad_ref_set) > 0
      assert MapSet.equal?(notepad_set, notepad_ref_set)
    end

    test "list_notepads/1 returns empty list (user without notepads)" do
      {users, notes, notepads} = notepad_fixture()
      [target_user | _] = users
      target_user = target_user |> Repo.preload(:notepads)
      Enum.each(target_user.notepads, fn np -> Notes.delete_notepad(np, target_user.id) end)
      target_user = target_user |> Repo.preload(:notepads, force: true)
      assert target_user.notepads == []

      assert Notes.list_notepads(target_user.id) == []
    end

    test "list_notepads/1 returns empty list (invalid user ID)" do
      assert Notes.list_notepads(@bad_id) == []
    end

    test "get_notepad/1 with valid notepad ID gets a single notepad" do
      {_, _, notepads} = notepad_fixture()
      [target_notepad | _] = notepads

      assert (%Notepad{} = n) = Notes.get_notepad(target_notepad.id)
      assert n.id == target_notepad.id
    end

    test "get_notepad/1 with invalid notepad ID returns nil" do
      assert is_nil(Notes.get_notepad(@bad_id))
    end

    test "create_notepad/1 with valid user ID creates a notepad such that owner == user ID" do
      {users, _, notepads} = notepad_fixture()
      [target_user | _ ] = users
      target_user = target_user |> Repo.preload(:notepads)
      f = fn x, acc -> MapSet.put(acc, x.id) end
      old_notepads = Enum.reduce(target_user.notepads, MapSet.new(), f)

      {:ok, %Notepad{} = np} = Notes.create_notepad(target_user.id)
      np = np |> Repo.preload(:user)
      assert np.user.id == target_user.id
      assert not MapSet.member?(old_notepads, np.id)
      target_user = target_user |> Repo.preload(:notepads, force: true)
      new_notepads = Enum.reduce(target_user.notepads, MapSet.new(), f)
      assert MapSet.subset?(old_notepads, new_notepads)
      assert MapSet.member?(new_notepads, np.id)
    end

    test "update_notepad/2 with valid data updates notepad" do
      {_, _, notepads} = notepad_fixture()
      [target_notepad | _] = notepads
      
      {:ok, %Notepad{} = np} = Notes.update_notepad(target_notepad, @update_attrs)
      assert np.id == target_notepad.id
      assert np.name == @update_attrs.name
      assert Repo.one(from n in Notepad, where: n.id == ^np.id) == np
    end

    test "update_notepad/2 with invalid data returns error" do
      {_, _, notepads} = notepad_fixture()
      [target_notepad | _] = notepads
      
      assert {:error, %Ecto.Changeset{}} = Notes.update_notepad(target_notepad, @invalid_attrs)
      assert Repo.one(from np in Notepad, where: np.id == ^target_notepad.id) == target_notepad
    end

  end
  
end
