defmodule SocialCircle.AccountsTest do
  use SocialCircle.DataCase

  alias SocialCircle.Accounts

  describe "users" do
    alias SocialCircle.Accounts.User

    import SocialCircle.AccountsFixtures

    @invalid_attrs %{email: nil, password: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "test@example.com", password: "validpassword123"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "test@example.com"
      assert Bcrypt.verify_pass("validpassword123", user.password_hash)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "create_user/1 with duplicate email returns error changeset" do
      user_fixture(%{email: "test@example.com"})
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{email: "test@example.com", password: "password123"})
    end

    test "authenticate_user/2 with valid credentials returns user" do
      user = user_fixture(%{email: "test@example.com", password: "validpassword123"})
      assert {:ok, authenticated_user} = Accounts.authenticate_user("test@example.com", "validpassword123")
      assert authenticated_user.id == user.id
    end

    test "authenticate_user/2 with invalid credentials returns error" do
      user_fixture(%{email: "test@example.com", password: "validpassword123"})
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("test@example.com", "wrongpassword")
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("wrong@example.com", "validpassword123")
    end
  end
end