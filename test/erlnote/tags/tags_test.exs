defmodule Erlnote.TagsTest do
  use Erlnote.DataCase

  alias Erlnote.Tags

  describe "tags" do
    alias Erlnote.Tags.Tag
    alias Erlnote.Accounts
    alias Erlnote.Accounts.User
    alias Erlnote.Notes
    alias Erlnote.Notes.{Notepad, NotepadTag, Note, NoteTag}
    alias Erlnote.Tasks
    alias Erlnote.Tasks.{Tasklist, TasklistTag}

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    @bad_id -1

    @user %{
      name: "User 1",
      username: "user1",
      credentials: [
        %{
          email: "user1@example.com",
          password: "superfreak"
        }
      ]
    }

    def tag_fixture(_attrs \\ %{}) do
      {:ok, tag} = Tags.create_tag(@valid_attrs.name)

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Tags.list_tags() == [tag]
    end

    test "get_tag/1 returns the tag with given id" do
      tag = tag_fixture()
      assert Tags.get_tag(tag.id) == tag
    end

    test "get_tag/1 returns nil with bad tag id" do
      assert Tags.get_tag(@bad_id) == nil
    end

    test "get_tag_by_name/1 returns the tag with given name" do
      tag = tag_fixture()
      assert Tags.get_tag_by_name(tag.name) == tag
    end

    test "get_tag_by_name/1 returns nil with non-existent tag name" do
      assert Tags.get_tag_by_name(Integer.to_string @bad_id) == nil
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Tags.create_tag(@valid_attrs.name)
      assert is_integer(tag.id)
      assert tag.name == @valid_attrs.name
      assert (from t in Tag, where: t.id == ^tag.id) |> Repo.one == tag
    end

    test "create_tag/1 with duplicated data returns same tag" do
      r = (1 .. 2) |> Enum.map(fn _ -> Tags.create_tag(@valid_attrs.name) end)
      target_tag = (from t in Tag, where: t.name == ^@valid_attrs.name) |> Repo.one
      assert r |> Enum.all?(fn x -> elem(x, 0) == :ok and elem(x, 1) == target_tag end)
    end

    test "update_tag/2 with valid data updates the tag" do
      t = tag_fixture()
      assert {:ok, %Tag{} = tag} = Tags.update_tag(t, @update_attrs)
      assert tag.name == @update_attrs.name
      assert tag.id == t.id
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(tag, @invalid_attrs)
      assert tag == Tags.get_tag(tag.id)
    end

    test "update_tag/2 with invalid tag name returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(tag, %{name: String.duplicate("asm", 255)})
      assert tag == Tags.get_tag(tag.id)
    end

    test "delete_tag/1 when is_map deletes the tag (#assoc(notepads) == 0 and #assoc(notes) == 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Tags.delete_tag(tag)
      assert Tags.get_tag(tag.id) == nil
    end

    test "delete_tag/1 when is_map returns error (#assoc(notepads) > 0 and #assoc(notes) == 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Notepad{} = notepad} = Notes.create_notepad(user.id)
      {:ok, %NotepadTag{}} = Notes.link_tag_to_notepad(notepad.id, user.id, tag.name)

      tag_with_notepads = tag |> Repo.preload(:notepads, force: true)
      assert length(tag_with_notepads.notepads) > 0
      assert {:error, _} = Tags.delete_tag(tag)
      assert Tags.get_tag(tag.id) |> Repo.preload(:notepads, force: true) == tag_with_notepads
    end

    test "delete_tag/1 when is_map returns error (#assoc(notepads) == 0 and #assoc(notes) > 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Note{} = note} = Notes.create_note(user.id)
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(note.id, user.id, tag.name)

      tag_with_notes = tag |> Repo.preload(:notes, force: true)
      assert length(tag_with_notes.notes) > 0
      assert {:error, _} = Tags.delete_tag(tag)
      assert Tags.get_tag(tag.id) |> Repo.preload(:notes, force: true) == tag_with_notes
    end

    test "delete_tag/1 when is_map returns error (#assoc(notepads) == 0 and #assoc(notes) == 0 and #assoc(taskslists) > 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Tasklist{} = tasklist} = Tasks.create_tasklist(user.id)
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(tasklist.id, user.id, tag.name)

      tag_with_tasklists = tag |> Repo.preload(:tasklists, force: true)
      assert length(tag_with_tasklists.tasklists) > 0
      assert {:error, _} = Tags.delete_tag(tag)
      assert Tags.get_tag(tag.id) |> Repo.preload(:tasklists, force: true) == tag_with_tasklists
    end

    test "delete_tag/1 when is_binary deletes the tag (#assoc(notepads) == 0 and #assoc(notes) == 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = Tags.delete_tag(tag.name)
      assert Tags.get_tag_by_name(tag.name) == nil
    end

    test "delete_tag/1 when is_binary returns error (#assoc(notepads) > 0 and #assoc(notes) == 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Notepad{} = notepad} = Notes.create_notepad(user.id)
      {:ok, %NotepadTag{}} = Notes.link_tag_to_notepad(notepad.id, user.id, tag.name)

      tag_with_notepads = tag |> Repo.preload(:notepads, force: true)
      assert length(tag_with_notepads.notepads) > 0
      assert {:error, _} = Tags.delete_tag(tag.name)
      assert Tags.get_tag_by_name(tag.name) |> Repo.preload(:notepads, force: true) == tag_with_notepads
    end

    test "delete_tag/1 when is_binary returns error (#assoc(notepads) == 0 and #assoc(notes) > 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Note{} = note} = Notes.create_note(user.id)
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(note.id, user.id, tag.name)

      tag_with_notes = tag |> Repo.preload(:notes, force: true)
      assert length(tag_with_notes.notes) > 0
      assert {:error, _} = Tags.delete_tag(tag.name)
      assert Tags.get_tag_by_name(tag.name) |> Repo.preload(:notes, force: true) == tag_with_notes
    end

    test "delete_tag/1 when is_binary returns error (#assoc(notepads) == 0 and #assoc(notes) == 0 and #assoc(taskslists) > 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Tasklist{} = tasklist} = Tasks.create_tasklist(user.id)
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(tasklist.id, user.id, tag.name)

      tag_with_tasklists = tag |> Repo.preload(:tasklists, force: true)
      assert length(tag_with_tasklists.tasklists) > 0
      assert {:error, _} = Tags.delete_tag(tag.name)
      assert Tags.get_tag_by_name(tag.name) |> Repo.preload(:tasklists, force: true) == tag_with_tasklists
    end

    test "force_delete_tag/1 when is_binary deletes the tag (#assoc(notepads) == 0 and #assoc(notes) == 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      assert %{delete_tag: {:ok, %Tag{} = t}} = Tags.force_delete_tag(tag.name)
      assert tag.id == t.id
      assert Tags.get_tag_by_name(tag.name) == nil
    end

    test "force_delete_tag/1 when is_binary deletes the tag (#assoc(notepads) > 0 and #assoc(notes) == 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Notepad{} = notepad} = Notes.create_notepad(user.id)
      {:ok, %NotepadTag{}} = Notes.link_tag_to_notepad(notepad.id, user.id, tag.name)

      tag_with_notepads = tag |> Repo.preload(:notepads, force: true)
      assert length(tag_with_notepads.notepads) > 0
      assert %{delete_tag: {:ok, %Tag{} = t}} = Tags.force_delete_tag(tag.name)
      assert tag.id == t.id
      assert Tags.get_tag_by_name(tag.name) == nil
      assert (from q in NotepadTag, where: q.notepad_id == ^notepad.id and q.tag_id == ^tag.id) |> Repo.all == []
    end

    test "force_delete_tag/1 when is_binary deletes the tag (#assoc(notepads) == 0 and #assoc(notes) > 0 and #assoc(taskslists) == 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Note{} = note} = Notes.create_note(user.id)
      {:ok, %NoteTag{}} = Notes.link_tag_to_note(note.id, user.id, tag.name)

      tag_with_notes = tag |> Repo.preload(:notes, force: true)
      assert length(tag_with_notes.notes) > 0
      assert %{delete_tag: {:ok, %Tag{} = t}} = Tags.force_delete_tag(tag.name)
      assert tag.id == t.id
      assert Tags.get_tag_by_name(tag.name) == nil
      assert (from q in NoteTag, where: q.note_id == ^note.id and q.tag_id == ^tag.id) |> Repo.all == []
    end

    test "force_delete_tag/1 when is_binary deletes the tag (#assoc(notepads) == 0 and #assoc(notes) == 0 and #assoc(taskslists) > 0)" do
      tag = tag_fixture()
      {:ok, %User{} = user} = Accounts.create_user(@user)
      {:ok, %Tasklist{} = tasklist} = Tasks.create_tasklist(user.id)
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(tasklist.id, user.id, tag.name)

      tag_with_tasklists = tag |> Repo.preload(:tasklists, force: true)
      assert length(tag_with_tasklists.tasklists) > 0
      assert %{delete_tag: {:ok, %Tag{} = t}} = Tags.force_delete_tag(tag.name)
      assert tag.id == t.id
      assert Tags.get_tag_by_name(tag.name) == nil
      assert (from q in TasklistTag, where: q.tasklist_id == ^tasklist.id and q.tag_id == ^tag.id) |> Repo.all == []
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = Tags.change_tag(tag)
    end
    
  end
end
