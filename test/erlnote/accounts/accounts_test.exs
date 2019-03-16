defmodule Erlnote.AccountsTest do
  use Erlnote.DataCase

  alias Erlnote.Accounts

  describe "users" do
    alias Erlnote.Accounts.User

    @valid_attrs %{
      name: "function2source",
      username: "f2src",
      credentials: [
        %{
          email: "f2src@example.com",
          password: "supersecretoyultraseguro"
        }
      ]
    }
    @update_attrs %{
      name: "foo",
      username: "bar"
    }
    @invalid_attrs %{
      name: "function2source",
      username: "f2srccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
    }
    @invalid_credential_attrs %{
      name: "function2source",
      username: "f2src",
      credentials: [
        %{
          email: "f2src",
          password: "corto"
        }
      ]
    }

    # Not for all test. Discard setup().
    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    defp get_user_without_assoc(%User{} = user) do
      {user.name, user.username}
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Enum.reduce(Accounts.list_users(), [], fn x, acc -> [{x.name, x.username}|acc] end) == [{user.name, user.username}]
    end

    test "get_user_by_id!/1 returns the user with given id" do
      user = user_fixture()
      assert get_user_without_assoc(Accounts.get_user_by_id!(user.id)) == get_user_without_assoc(user)
    end

    test "get_user_by_id/1 returns the user with given id" do
      user = user_fixture()
      assert get_user_without_assoc(Accounts.get_user_by_id(user.id)) == get_user_without_assoc(user)
    end

    test "get_user_by_username/1 returns the user with given username" do
      user = user_fixture()
      assert get_user_without_assoc(Accounts.get_user_by_username(user.username)) == get_user_without_assoc(user)
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.name == "function2source"
      assert user.username == "f2src"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_credential_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.name == "foo"
      assert user.username == "bar"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert get_user_without_assoc(Accounts.get_user_by_id(user.id)) == get_user_without_assoc(user)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user_by_id!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
