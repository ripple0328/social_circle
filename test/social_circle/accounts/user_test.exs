defmodule SocialCircle.Accounts.UserTest do
  @moduledoc """
  Unit tests for the User Ash resource.
  
  Tests cover:
  - User creation with OAuth data
  - Validations and constraints
  - Account linking functionality
  - Calculations and relationships
  """
  
  use SocialCircle.DataCase
  
  alias SocialCircle.Accounts.{User, LinkedProvider}

  describe "create_from_oauth action" do
    test "creates user with valid OAuth data" do
      unique_id = System.unique_integer([:positive])
      assert {:ok, user} = User
             |> Ash.Changeset.for_create(:create_from_oauth, %{
               email: "test_#{unique_id}@example.com",
               provider: :x,
               provider_id: "x#{unique_id}",
               name: "Test User",
               avatar_url: "https://example.com/avatar.jpg"
             })
             |> Ash.create(actor: test_actor())

      assert user.email == "test_#{unique_id}@example.com"
      assert user.provider == :x
      assert user.provider_id == "x#{unique_id}"
      assert user.name == "Test User"
      assert user.avatar_url == "https://example.com/avatar.jpg"
    end

    test "requires email, provider, and provider_id" do
      assert {:error, %Ash.Error.Invalid{}} = User
             |> Ash.Changeset.for_create(:create_from_oauth, %{
               provider: :x,
               provider_id: "x123"
               # missing email
             })
             |> Ash.create(actor: test_actor())
    end

    test "validates email format" do
      assert {:error, %Ash.Error.Invalid{}} = User
             |> Ash.Changeset.for_create(:create_from_oauth, %{
               email: "invalid-email",
               provider: :x,
               provider_id: "x123"
             })
             |> Ash.create(actor: test_actor())
    end

    test "validates provider is one of allowed values" do
      assert {:error, %Ash.Error.Invalid{}} = User
             |> Ash.Changeset.for_create(:create_from_oauth, %{
               email: "test_#{System.unique_integer([:positive])}@example.com",
               provider: :invalid_provider,
               provider_id: "x123"
             })
             |> Ash.create(actor: test_actor())
    end
  end

  describe "find_or_create_from_oauth action" do
    test "creates new user when email doesn't exist" do
      assert {:ok, user} = User
             |> Ash.Changeset.for_create(:find_or_create_from_oauth, %{
               email: "new@example.com",
               provider: :x,
               provider_id: "x123",
               name: "New User"
             })
             |> Ash.create(actor: test_actor())

      assert user.email == "new@example.com"
      assert user.provider == :x
    end

    test "finds existing user by email" do
      # Create initial user
      {:ok, existing_user} = User
                             |> Ash.Changeset.for_create(:create_from_oauth, %{
                               email: "existing@example.com",
                               provider: :x,
                               provider_id: "x123",
                               name: "Existing User"
                             })
                             |> Ash.create(actor: test_actor())

      # Try to create with same email
      assert {:ok, found_user} = User
                                 |> Ash.Changeset.for_create(:find_or_create_from_oauth, %{
                                   email: "existing@example.com",
                                   provider: :facebook,
                                   provider_id: "fb456",
                                   name: "Updated Name"
                                 })
                                 |> Ash.create(actor: test_actor())

      # Should return the existing user
      assert found_user.id == existing_user.id
      assert found_user.email == "existing@example.com"
      # Original provider should remain unchanged
      assert found_user.provider == :x
    end
  end

  describe "link_provider action" do
    test "successfully links additional provider to existing user" do
      # Create initial user
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Link Facebook provider
      assert {:ok, updated_user} = user
                                   |> Ash.Changeset.for_update(:link_provider, %{
                                     provider: :facebook,
                                     provider_id: "fb456",
                                     avatar_url: "https://example.com/fb_avatar.jpg"
                                   })
                                   |> Ash.update(actor: user)

      # Verify linked provider was created
      linked_providers = updated_user.linked_providers
      assert length(linked_providers) == 1
      
      linked_provider = List.first(linked_providers)
      assert linked_provider.provider == :facebook
      assert linked_provider.provider_id == "fb456"
      assert linked_provider.user_id == user.id
    end

    test "prevents linking same provider as primary account" do
      # Create user with X as primary
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Try to link X again (same provider as primary)
      assert {:error, %Ash.Error.Invalid{}} = user
                                              |> Ash.Changeset.for_update(:link_provider, %{
                                                provider: :x,
                                                provider_id: "x123"
                                              })
                                              |> Ash.update(actor: user)
    end

    test "prevents linking provider already used by another user" do
      # Create first user with Facebook
      {:ok, _other_user} = User
                           |> Ash.Changeset.for_create(:create_from_oauth, %{
                             email: "other@example.com",
                             provider: :facebook,
                             provider_id: "fb123",
                             name: "Other User"
                           })
                           |> Ash.create(actor: test_actor())

      # Create second user with X
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Try to link Facebook with same provider_id
      assert {:error, %Ash.Error.Invalid{}} = user
                                              |> Ash.Changeset.for_update(:link_provider, %{
                                                provider: :facebook,
                                                provider_id: "fb123"
                                              })
                                              |> Ash.update(actor: user)
    end
  end

  describe "calculations" do
    test "primary_provider calculation returns user's main provider" do
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      user_with_calc = User
                      |> Ash.get!(user.id, actor: test_actor())
                      |> Ash.load!([:primary_provider], actor: test_actor())

      assert user_with_calc.primary_provider == :x
    end

    test "connected_providers calculation includes primary and linked providers" do
      # Create user with X as primary
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Add linked providers
      {:ok, _linked1} = LinkedProvider
                       |> Ash.Changeset.for_create(:create, %{
                         user_id: user.id,
                         provider: :facebook,
                         provider_id: "fb456"
                       })
                       |> Ash.create(actor: test_actor())

      {:ok, _linked2} = LinkedProvider
                       |> Ash.Changeset.for_create(:create, %{
                         user_id: user.id,
                         provider: :google,
                         provider_id: "google789"
                       })
                       |> Ash.create(actor: test_actor())

      # Load with calculation
      user_with_calc = User
                      |> Ash.get!(user.id, actor: test_actor())
                      |> Ash.load!([:connected_providers], actor: test_actor())

      connected = user_with_calc.connected_providers
      assert :x in connected
      assert :facebook in connected
      assert :google in connected
      assert length(connected) == 3
    end
  end

  describe "identities and constraints" do
    test "unique_email identity prevents duplicate emails" do
      # Create first user
      {:ok, _user1} = User
                     |> Ash.Changeset.for_create(:create_from_oauth, %{
                       email: "duplicate@example.com",
                       provider: :x,
                       provider_id: "x123",
                       name: "First User"
                     })
                     |> Ash.create(actor: test_actor())

      # Try to create second user with same email (should upsert)
      {:ok, user2} = User
                    |> Ash.Changeset.for_create(:find_or_create_from_oauth, %{
                      email: "duplicate@example.com",
                      provider: :facebook,
                      provider_id: "fb456",
                      name: "Second User"
                    })
                    |> Ash.create(actor: test_actor())

      # Should return the existing user
      assert user2.email == "duplicate@example.com"
      assert user2.provider == :x  # Original provider preserved
    end

    test "unique_provider_account identity prevents duplicate provider+provider_id" do
      # Create first user
      {:ok, _user1} = User
                     |> Ash.Changeset.for_create(:create_from_oauth, %{
                       email: "user1@example.com",
                       provider: :x,
                       provider_id: "x123",
                       name: "First User"
                     })
                     |> Ash.create(actor: test_actor())

      # Try to create second user with same provider+provider_id
      assert {:error, %Ash.Error.Invalid{}} = User
                                              |> Ash.Changeset.for_create(:create_from_oauth, %{
                                                email: "user2@example.com",
                                                provider: :x,
                                                provider_id: "x123",
                                                name: "Second User"
                                              })
                                              |> Ash.create(actor: test_actor())
    end
  end
end