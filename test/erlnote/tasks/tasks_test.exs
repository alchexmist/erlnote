defmodule Erlnote.TasksTest do
  use Erlnote.DataCase

  alias Erlnote.Tasks

  describe "tasks" do
    alias Erlnote.Tasks.{Task, TasklistTag, TasklistUser, Tasklist}
    alias Erlnote.Accounts
    alias Erlnote.Tags
    alias Erlnote.Tags.Tag

    @string_min_len 1
    @string_max_len 255
    @bad_id -1
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

    @valid_task_attrs %{description: "some description", end_datetime: "2010-04-17T18:00:00Z", name: "task one", priority: "LOW", start_datetime: "2010-04-17T14:00:00Z", state: "INPROGRESS"}
    @update_task_attrs %{description: "some updated description", end_datetime: "2011-05-18T15:01:01Z", name: "task two", priority: "NORMAL", start_datetime: "2011-05-18T14:01:01Z", state: "FINISHED"}
    # @invalid_attrs %{description: nil, end_datetime: nil, name: nil, priority: nil, start_datetime: nil, state: nil}

    @valid_attrs %{deleted: false, title: "White list"}
    @update_attrs %{deleted: false, title: "Black list"}
    @invalid_attrs %{deleted: "XFree86", title: "White list"}

    def task_fixture(_attrs \\ %{}) do
      users = @users |> Enum.reduce([], fn u, acc -> [elem(Accounts.create_user(u), 1) | acc] end)
      tasklists = for {:ok, %Tasklist{} = t} <- Enum.map(users, fn u -> Tasks.create_tasklist(Accounts.get_id(u)) end), do: t
      
      {users, tasklists}
    end

    defp contains_tasklist?(_, [], acc), do: acc
    defp contains_tasklist?(%Tasklist{} = tasklist, tasklist_list, acc) when is_list(tasklist_list) do
      [%Tasklist{} = h | t] = tasklist_list
      h = h |> Repo.preload(:user)
      tasklist = tasklist |> Repo.preload(:user)
      r = if h.id == tasklist.id and h.user == tasklist.user do
        [true | acc]
      else
        acc
      end
      contains_tasklist?(tasklist, t, r)
    end
    defp contains_tasklist?(%Tasklist{} = tasklist, tasklist_list) when is_list(tasklist_list) do
      contains_tasklist?(tasklist, tasklist_list, [])
    end

    test "create_tasklist/1 with valid data creates a tasklist" do
      {users, _} = task_fixture()
      [target_user | _] = users
      assert {:ok, %Tasklist{} = t} = Tasks.create_tasklist(target_user.id)
      assert not is_nil(t.id) and t.id > 0
      assert (from tl in assoc(target_user, :owner_tasklists), where: tl.id == ^t.id) |> Repo.one == t
      t = t |> Repo.preload(:user)
      assert t.user.id == target_user.id
      assert t.deleted == false
      assert not is_nil(t.title)
      title_len = String.length(t.title)
      assert title_len >= @string_min_len and title_len <= @string_max_len
    end

    test "create_tasklist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_tasklist(@bad_id)
    end

    test "list_is_owner_tasklists/1 returns all user's tasklists" do
      {users, tasklists} = task_fixture()
      [target_user | _] = users 
      owner_tasklists = Tasks.list_is_owner_tasklists(target_user.id)

      r = for ot <- owner_tasklists do
        contains_tasklist?(ot, tasklists)
      end
      |> List.flatten
      |> Enum.count(fn x -> x == true end)

      assert r == 1
    end

    test "list_is_owner_tasklists/1 with invalid data returns the empty list" do
      assert Tasks.list_is_owner_tasklists(@bad_id) == []
    end

    test "list_is_contributor_tasklists/1 with valid data returns all tasklists in which the user acts as a contributor" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert target_tasklist.users == []
      assert {:ok, %TasklistUser{} = tasklist_user} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)
      tasklist_list = Tasks.list_is_contributor_tasklists(contributor_id)
      assert length(tasklist_list) == 1
      [t | []] = tasklist_list
      t = t |> Repo.preload([:users], force: true)
      assert t.id == target_tasklist.id
      assert t.id == tasklist_user.tasklist_id
      assert Enum.find(t.users, [], fn x -> x.id == tasklist_user.user_id end) != []
    end

    test "list_is_contributor_tasklists/1 with invalid data returns the empty list" do
      assert Tasks.list_is_contributor_tasklists(@bad_id) == []
    end

    test "get_tasklist/1 returns the tasklist with given id" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      assert Tasks.get_tasklist(target_tasklist.id) == target_tasklist
    end

    test "get_tasklist/1 returns nil with invalid id" do
      assert is_nil(Tasks.get_tasklist(@bad_id))
    end

    test "update_tasklist/3 with valid data updates the tasklist" do
      {_, tasklists} = task_fixture()
      [t | _] = tasklists
      t = t |> Repo.preload(:user)
      assert {:ok, %Tasklist{} = tl} = Tasks.update_tasklist(t.user.id, t.id, @update_attrs)
      assert tl.title == @update_attrs.title
      assert tl.deleted == @update_attrs.deleted
      assert tl.id == t.id
      assert (from r in Tasklist, where: r.id == ^t.id) |> Repo.one == tl
    end

    test "update_tasklist/3 with invalid data returns error changeset" do
      {_, tasklists} = task_fixture()
      [t | _] = tasklists
      target_t = t |> Repo.preload(:user)
      assert {:error, %Ecto.Changeset{}} = Tasks.update_tasklist(target_t.user.id, target_t.id, @invalid_attrs)
      assert t == Tasks.get_tasklist(t.id)
    end

    test "update_tasklist/3 with invalid tasklist_id returns error tuple" do
      {users, _} = task_fixture()
      [user | _] = users
      assert {:error, _} = Tasks.update_tasklist(user.id, @bad_id, @update_attrs)
    end

    test "update_tasklist/3 with invalid user_id returns error tuple" do
      {_, tasklists} = task_fixture()
      [t | _] = tasklists
      assert {:error, _} = Tasks.update_tasklist(@bad_id, t.id, @update_attrs)
    end

    test "delete_tasklist/2 with user ID == owner ID and contributors == [] deletes tasklist" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)

      assert {:ok, %Tasklist{} = t} = Tasks.delete_tasklist(target_tasklist, target_tasklist.user.id)
      assert target_tasklist.id == t.id
      assert Repo.all(from tl in Tasklist, where: tl.id == ^target_tasklist.id) == []
      assert Repo.all(from tt in TasklistTag, where: tt.tasklist_id == ^target_tasklist.id) == []
    end

    test "delete_tasklist/2 with user ID == owner ID and contributors != [] keeps the tasklist and sets up deleted as true" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      contributor_id = Enum.find(users, fn c -> c.id != target_tasklist.user.id end).id
      
      {:ok, %TasklistUser{}} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)

      assert target_tasklist.deleted == false
      assert {:ok, %Tasklist{} = r} = Tasks.delete_tasklist(target_tasklist, target_tasklist.user.id)
      assert r.id == target_tasklist.id and r.deleted == true
      assert [updated_tasklist | []] = Repo.all(from t in Tasklist, where: t.id == ^target_tasklist.id)
      assert updated_tasklist.deleted == true
    end

    test "delete_tasklist/2 with user ID == contributor ID and contributors == [contributor] and owner == unowned deletes tasklist" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      contributor_id = Enum.find(users, fn c -> c.id != target_tasklist.user.id end).id
      
      {:ok, %TasklistUser{}} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)

      {:ok, %Tasklist{}} = Tasks.delete_tasklist(target_tasklist, target_tasklist.user.id)
      [updated_tasklist | []] = Repo.all(from t in Tasklist, where: t.id == ^target_tasklist.id)
      assert updated_tasklist.deleted == true
      {:ok, %Tasklist{} = tl} = Tasks.delete_tasklist(updated_tasklist, contributor_id)
      assert target_tasklist.id == tl.id
      assert Repo.all(from t in Tasklist, where: t.id == ^target_tasklist.id) == []
      assert Repo.all(from tu in TasklistUser, where: tu.tasklist_id == ^target_tasklist.id) == []
    end

    test "delete_tasklist/2 with user ID == contributor ID and contributors == [contributor0, contributor1] and owner == unowned keeps the tasklist" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      unique_users = Enum.uniq_by(users, fn user -> user.id end) |> Enum.reject(fn y -> y.id == target_tasklist.user.id end)
      [contributor | contributors] = unique_users
      [contributor2 | _] = contributors
      contributor_id = contributor.id
      contributor_id2 = contributor2.id

      {:ok, %TasklistUser{}} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)
      {:ok, %TasklistUser{}} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id2, true, true)
      
      {:ok, %Tasklist{}} = Tasks.delete_tasklist(target_tasklist, target_tasklist.user.id)
      [updated_tasklist | []] = Repo.all(from t in Tasklist, where: t.id == ^target_tasklist.id)
      assert updated_tasklist.deleted == true

      {:ok, %Tasklist{} = tl} = Tasks.delete_tasklist(updated_tasklist, contributor_id)
      assert target_tasklist.id == tl.id
      assert length(tl.users) > 0
      assert is_nil(Enum.find(tl.users, fn u -> u.id == contributor_id end))
      assert [hd | []] = Repo.all(from t in Tasklist, where: t.id == ^target_tasklist.id)
      assert [hd | []] = Repo.all(from tu in TasklistUser, where: tu.tasklist_id == ^target_tasklist.id and tu.user_id == ^contributor_id2)
      assert [] = Repo.all(from tu in TasklistUser, where: tu.tasklist_id == ^target_tasklist.id and tu.user_id == ^contributor_id)
    end

    test "link_tasklist_to_user/5 with valid data adds a contributor on the tasklist" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert target_tasklist.users == []
      assert {:ok, %TasklistUser{} = tasklist_user} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)
      assert tasklist_user.tasklist_id == target_tasklist.id and tasklist_user.user_id == contributor_id
      assert Enum.find(Tasks.list_is_contributor_tasklists(contributor_id), [], fn x -> x.id == target_tasklist.id end) != []
      assert not is_nil(Repo.one(from tu in TasklistUser, where: tu.user_id == ^contributor_id and tu.tasklist_id == ^target_tasklist.id))
    end

    test "link_tasklist_to_user/5 with valid data (write enabled/read disabled) adds a contributor on the tasklist (write enabled/read disabled)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert target_tasklist.users == []
      assert {:ok, %TasklistUser{} = tasklist_user} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, false, true)
      assert Enum.find(Tasks.list_is_contributor_tasklists(contributor_id), [], fn x -> x.id == target_tasklist.id end) != []
      assert not is_nil(r = Repo.one(from tu in TasklistUser, where: tu.user_id == ^contributor_id and tu.tasklist_id == ^target_tasklist.id))
      assert Tasks.can_write?(r.user_id, r.tasklist_id) == true
      assert Tasks.can_read?(r.user_id, r.tasklist_id) == false
    end

    test "link_tasklist_to_user/5 with valid data (write disabled/read enabled) adds a contributor on the tasklist (write disabled/read enabled)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert target_tasklist.users == []
      assert {:ok, %TasklistUser{} = tasklist_user} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, false)
      assert Enum.find(Tasks.list_is_contributor_tasklists(contributor_id), [], fn x -> x.id == target_tasklist.id end) != []
      assert not is_nil(r = Repo.one(from tu in TasklistUser, where: tu.user_id == ^contributor_id and tu.tasklist_id == ^target_tasklist.id))
      assert Tasks.can_write?(r.user_id, r.tasklist_id) == false
      assert Tasks.can_read?(r.user_id, r.tasklist_id) == true
    end

    test "link_tasklist_to_user/5 with invalid owner ID returns permission denied error" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert target_tasklist.users == []
      assert {:error, "Permission denied."} = Tasks.link_tasklist_to_user(@bad_id, target_tasklist.id, contributor_id, true, true)
      assert Enum.find(Tasks.list_is_contributor_tasklists(contributor_id), [], fn x -> x.id == target_tasklist.id end) == []
      assert is_nil(Repo.one(from tu in TasklistUser, where: tu.user_id == ^contributor_id and tu.tasklist_id == ^target_tasklist.id))
    end

    test "link_tasklist_to_user/5 with invalid note ID returns a error" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert target_tasklist.users == []
      assert {:error, "User ID or tasklist ID not found."} = Tasks.link_tasklist_to_user(target_tasklist.user.id, @bad_id, contributor_id, true, true)
      assert Enum.find(Tasks.list_is_contributor_tasklists(contributor_id), [], fn x -> x.id == target_tasklist.id end) == []
      assert is_nil(Repo.one(from tu in TasklistUser, where: tu.user_id == ^contributor_id and tu.tasklist_id == ^target_tasklist.id))
    end

    test "link_tasklist_to_user/5 with invalid user ID returns a error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = @bad_id

      assert target_tasklist.users == []
      assert {:error, "User ID or tasklist ID not found."} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)
      assert Enum.find(Tasks.list_is_contributor_tasklists(contributor_id), [], fn x -> x.id == target_tasklist.id end) == []
      assert is_nil(Repo.one(from tu in TasklistUser, where: tu.user_id == ^contributor_id and tu.tasklist_id == ^target_tasklist.id))
    end

    test "set_can_read_from_tasklist/3 with valid data enables/disables read permission for (contributor, tasklist)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      {:ok, %TasklistUser{} = _} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)
      assert Tasks.can_read?(contributor_id, target_tasklist.id) == true
      assert {:ok, %TasklistUser{}} = Tasks.set_can_read_from_tasklist(contributor_id, target_tasklist.id, false)
      assert Tasks.can_read?(contributor_id, target_tasklist.id) == false
      assert {:ok, %TasklistUser{}} = Tasks.set_can_read_from_tasklist(contributor_id, target_tasklist.id, true)
      assert Tasks.can_read?(contributor_id, target_tasklist.id) == true
    end

    test "set_can_read_from_tasklist/3 with invalid contributor ID returns error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists

      assert {:error, _} = Tasks.set_can_read_from_tasklist(@bad_id, target_tasklist.id, false)
    end

    test "set_can_read_from_tasklist/3 with invalid note ID returns error" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert {:error, _} = Tasks.set_can_read_from_tasklist(contributor_id, @bad_id, false)
    end

    test "set_can_write_to_tasklist/3 with valid data enables/disables write permission for (contributor, tasklist)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      {:ok, %TasklistUser{}} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, contributor_id, true, true)
      assert Tasks.can_write?(contributor_id, target_tasklist.id) == true
      assert {:ok, %TasklistUser{}} = Tasks.set_can_write_to_tasklist(contributor_id, target_tasklist.id, false)
      assert Tasks.can_write?(contributor_id, target_tasklist.id) == false
      assert {:ok, %TasklistUser{}} = Tasks.set_can_write_to_tasklist(contributor_id, target_tasklist.id, true)
      assert Tasks.can_write?(contributor_id, target_tasklist.id) == true
    end

    test "set_can_write_to_tasklist/3 with invalid contributor ID returns error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists

      assert {:error, _} = Tasks.set_can_write_to_tasklist(@bad_id, target_tasklist.id, false)
    end

    test "set_can_write_to_tasklist/3 with invalid note ID returns error" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      contributor_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert {:error, _} = Tasks.set_can_write_to_tasklist(contributor_id, @bad_id, false)
    end

    test "can_write?/2 always returns true (owner of the tasklist)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user])
      
      assert Tasks.can_write?(target_tasklist.user.id, target_tasklist.id) == true
    end

    test "can_write?/2 always returns true or false (contributor of the tasklist)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id
      collaborator_id2 = Enum.find(users, fn u -> u.id not in [target_tasklist.user.id, collaborator_id] end).id

      {:ok, %TasklistUser{} = _} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, collaborator_id, true, true)
      {:ok, %TasklistUser{} = _} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, collaborator_id2, true, false)

      assert Tasks.can_write?(collaborator_id, target_tasklist.id) == true
      assert Tasks.can_write?(collaborator_id2, target_tasklist.id) == false
    end

    test "can_write?/2 always returns false (invalid IDs)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user])
      collaborator_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert Tasks.can_write?(@bad_id, target_tasklist.id) == false
      assert Tasks.can_write?(collaborator_id, @bad_id) == false
    end

    test "can_read?/2 always returns true (owner of the tasklist)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user])
      
      assert Tasks.can_read?(target_tasklist.user.id, target_tasklist.id) == true
    end

    test "can_read?/2 always returns true or false (contributor of the tasklist)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :users])
      collaborator_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id
      collaborator_id2 = Enum.find(users, fn u -> u.id not in [target_tasklist.user.id, collaborator_id] end).id

      {:ok, %TasklistUser{} = _} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, collaborator_id, true, true)
      {:ok, %TasklistUser{} = _} = Tasks.link_tasklist_to_user(target_tasklist.user.id, target_tasklist.id, collaborator_id2, false, true)

      assert Tasks.can_read?(collaborator_id, target_tasklist.id) == true
      assert Tasks.can_read?(collaborator_id2, target_tasklist.id) == false
    end

    test "can_read?/2 always returns false (invalid IDs)" do
      {users, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user])
      collaborator_id = Enum.find(users, fn u -> u.id != target_tasklist.user.id end).id

      assert Tasks.can_read?(@bad_id, target_tasklist.id) == false
      assert Tasks.can_read?(collaborator_id, @bad_id) == false
    end

    test "get_tags_from_tasklist/1 lists all the associated tags (tasklist with tags)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      [tag_name_x | tail] = @valid_tag_name_list
      [tag_name_y | _] = tail

      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, tag_name_x)
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, tag_name_y)
      tag_list = Tasks.get_tags_from_tasklist(target_tasklist.id)
      assert length(tag_list) == 2
      tn1 = List.first(tag_list).name
      tn2 = List.last(tag_list).name
      assert tag_name_x == tn1 or tag_name_x == tn2
      assert tag_name_y == tn1 or tag_name_y == tn2
    end

    test "get_tags_from_tasklist/1 returns empty list (tasklist without tags)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :tags)
      
      assert target_tasklist.tags == []
      assert Tasks.get_tags_from_tasklist(target_tasklist.id) == []
    end

    test "get_tags_from_tasklist/1 with invalid tasklist ID returns empty list" do
      assert Tasks.get_tags_from_tasklist(@bad_id) == []
    end

    test "link_tag_to_tasklist/3 with valid data creates assoc(tasklist, tag)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :tags])
      
      assert target_tasklist.tags == []
      assert {:ok, %TasklistTag{} = tt} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert tt.tasklist_id == target_tasklist.id
      (%Tag{} = t) = Tags.get_tag_by_name(@valid_tag_name)
      assert tt.tag_id == t.id
      assert not is_nil(Repo.one(from r in assoc(target_tasklist, :tags), where: r.id == ^t.id and r.name == ^@valid_tag_name))
    end

    test "link_tag_to_tasklist/3 with duplicated tag name does nothing" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :tags])
      
      assert target_tasklist.tags == []
      assert {:ok, %TasklistTag{} = tt} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert {:ok, msg} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert is_binary msg
      assert tt.tasklist_id == target_tasklist.id
      (%Tag{} = t) = Tags.get_tag_by_name(@valid_tag_name)
      assert tt.tag_id == t.id
      assert not is_nil(Repo.one(from r in assoc(target_tasklist, :tags), where: r.id == ^t.id and r.name == ^@valid_tag_name))
    end

    test "link_tag_to_tasklist/3 with invalid note ID returns error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      
      assert {:error, msg} = Tasks.link_tag_to_tasklist(@bad_id, target_tasklist.user.id, @valid_tag_name)
    end

    test "link_tag_to_tasklist/3 with invalid user ID returns error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, [:user, :tags])
      
      assert target_tasklist.tags == []
      assert {:error, msg} = Tasks.link_tag_to_tasklist(target_tasklist.id, @bad_id, @valid_tag_name)
      assert Repo.all(from r in TasklistTag, where: r.tasklist_id == ^target_tasklist.id and r.tag_id == ^@bad_id) == []
    end

    test "remove_tag_from_tasklist/3 with valid data breaks assoc(tasklist, tag)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert not is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist.id), fn t -> @valid_tag_name == t.name end))
      %{remove_tag_from_tasklist: {1, nil}, delete_tag: {:ok, %Tag{}}} = Tasks.remove_tag_from_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist.id), fn t -> @valid_tag_name == t.name end))
    end

    test "remove_tag_from_tasklist/3 with valid data breaks assoc(tasklist, tag). (tag_name_in_use_by_other_entities)" do
      {_, tasklists} = task_fixture()
      [target_tasklist | other_tasklists] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      [target_tasklist2 | _] = other_tasklists
      target_tasklist2 = Repo.preload(target_tasklist2, :user)
      
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist2.id, target_tasklist2.user.id, @valid_tag_name)
      assert not is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist.id), fn t -> @valid_tag_name == t.name end))
      assert not is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist2.id), fn t -> @valid_tag_name == t.name end))
      %{remove_tag_from_tasklist: {1, nil}, delete_tag: {:error, _}} = Tasks.remove_tag_from_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist.id), fn t -> @valid_tag_name == t.name end))
      assert not is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist2.id), fn t -> @valid_tag_name == t.name end))
    end

    test "remove_tag_from_tasklist/3 with invalid tasklist ID returns error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      
      assert {:error, _} = Tasks.remove_tag_from_tasklist(@bad_id, target_tasklist.user.id, @valid_tag_name)
    end

    test "remove_tag_from_tasklist/3 with invalid user ID returns error" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)
      
      {:ok, %TasklistTag{}} = Tasks.link_tag_to_tasklist(target_tasklist.id, target_tasklist.user.id, @valid_tag_name)
      assert not is_nil(Enum.find(Tasks.get_tags_from_tasklist(target_tasklist.id), fn t -> @valid_tag_name == t.name end))
      {:error, _} = Tasks.remove_tag_from_tasklist(target_tasklist.id, @bad_id, @valid_tag_name)
    end
    
    test "list_tasks_from_tasklist/1 with valid tasklist ID returns all tasks in the list" do
      {_, tasklists} = task_fixture()
      [target_tasklist | _] = tasklists
      target_tasklist = Repo.preload(target_tasklist, :user)

      assert Tasks.list_tasks_from_tasklist(target_tasklist.id) == []
      {:ok, %Task{} = t1} = Tasks.add_task_to_tasklist(target_tasklist.user.id, target_tasklist.id, @valid_task_attrs)
      {:ok, %Task{} = t2} = Tasks.add_task_to_tasklist(target_tasklist.user.id, target_tasklist.id, @update_task_attrs)
      {task1, task2} = Tasks.list_tasks_from_tasklist(target_tasklist.id) |> List.pop_at(0)
      {task2, _} = List.pop_at(task2, 0)
      assert t1 == task1 or t1 == task2
      assert t2 == task1 or t2 == task2
    end

  end
end
