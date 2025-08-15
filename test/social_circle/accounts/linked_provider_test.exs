defmodule SocialCircle.Accounts.LinkedProviderTest do
  @moduledoc """
  Unit tests for the LinkedProvider Ash resource.
  
  Tests cover:
  - LinkedProvider creation
  - Validations and constraints
  - Relationships with User
  """
  
  use SocialCircle.DataCase
  
  alias SocialCircle.Accounts.{User, LinkedProvider}

  describe "create action" do
    setup do
      unique_id = System.unique_integer([:positive])
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{unique_id}@example.com",
                     provider: :x,
                     provider_id: "x#{unique_id}",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      %{user: user}
    end

    test "creates linked provider with valid data", %{user: user} do
      assert {:ok, linked_provider} = LinkedProvider
                                     |> Ash.Changeset.for_create(:create, %{
                                       user_id: user.id,
                                       provider: :facebook,
                                       provider_id: "fb456",
                                       avatar_url: "https://example.com/avatar.jpg",
                                       raw_data: %{"platform" => "facebook"}
                                     })
                                     |> Ash.create(actor: test_actor())

      assert linked_provider.user_id == user.id
      assert linked_provider.provider == :facebook
      assert linked_provider.provider_id == "fb456"
      assert linked_provider.avatar_url == "https://example.com/avatar.jpg"
      assert linked_provider.raw_data == %{"platform" => "facebook"}
    end

    test "requires user_id, provider, and provider_id", %{user: user} do
      # Missing provider
      assert {:error, %Ash.Error.Invalid{}} = LinkedProvider
                                              |> Ash.Changeset.for_create(:create, %{
                                                user_id: user.id,
                                                provider_id: "fb456"
                                              })
                                              |> Ash.create(actor: test_actor())

      # Missing provider_id
      assert {:error, %Ash.Error.Invalid{}} = LinkedProvider
                                              |> Ash.Changeset.for_create(:create, %{
                                                user_id: user.id,
                                                provider: :facebook
                                              })
                                              |> Ash.create(actor: test_actor())

      # Missing user_id
      assert {:error, %Ash.Error.Invalid{}} = LinkedProvider
                                              |> Ash.Changeset.for_create(:create, %{
                                                provider: :facebook,
                                                provider_id: "fb456"
                                              })
                                              |> Ash.create(actor: test_actor())
    end

    test "validates provider is one of allowed values", %{user: user} do
      assert {:error, %Ash.Error.Invalid{}} = LinkedProvider
                                              |> Ash.Changeset.for_create(:create, %{
                                                user_id: user.id,
                                                provider: :invalid_provider,
                                                provider_id: "invalid123"
                                              })
                                              |> Ash.create(actor: test_actor())
    end

    test "sets default empty map for raw_data", %{user: user} do
      {:ok, linked_provider} = LinkedProvider
                               |> Ash.Changeset.for_create(:create, %{
                                 user_id: user.id,
                                 provider: :facebook,
                                 provider_id: "fb456"
                               })
                               |> Ash.create(actor: test_actor())

      assert linked_provider.raw_data == %{}
    end
  end

  describe "relationships" do
    test "belongs_to user relationship works correctly" do
      # Create user
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Create linked provider
      {:ok, linked_provider} = LinkedProvider
                               |> Ash.Changeset.for_create(:create, %{
                                 user_id: user.id,
                                 provider: :facebook,
                                 provider_id: "fb456"
                               })
                               |> Ash.create(actor: test_actor())

      # Load the user relationship
      loaded_linked_provider = LinkedProvider
                               |> Ash.get!(linked_provider.id, actor: test_actor())
                               |> Ash.load!([:user], actor: test_actor())

      assert loaded_linked_provider.user.id == user.id
      assert String.contains?(loaded_linked_provider.user.email, "@example.com")
    end

    test "user has_many linked_providers relationship works" do
      # Create user
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Create multiple linked providers
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

      # Load user with linked providers
      user_with_providers = User
                           |> Ash.get!(user.id, actor: test_actor())
                           |> Ash.load!([:linked_providers], actor: test_actor())

      assert length(user_with_providers.linked_providers) == 2
      
      provider_types = Enum.map(user_with_providers.linked_providers, & &1.provider)
      assert :facebook in provider_types
      assert :google in provider_types
    end
  end

  describe "identities" do
    test "unique_linked_provider identity prevents duplicate provider+provider_id" do
      # Create user
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # Create first linked provider
      {:ok, _linked1} = LinkedProvider
                       |> Ash.Changeset.for_create(:create, %{
                         user_id: user.id,
                         provider: :facebook,
                         provider_id: "fb456"
                       })
                       |> Ash.create(actor: test_actor())

      # Try to create another linked provider with same provider+provider_id
      assert {:error, %Ash.Error.Invalid{}} = LinkedProvider
                                              |> Ash.Changeset.for_create(:create, %{
                                                user_id: user.id,
                                                provider: :facebook,
                                                provider_id: "fb456"
                                              })
                                              |> Ash.create(actor: test_actor())
    end

    test "allows same provider_id for different providers" do
      # Create user
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      # This scenario is unlikely in real OAuth but tests the identity constraint
      same_id = "same123"

      # Create linked provider with Facebook
      {:ok, _linked1} = LinkedProvider
                       |> Ash.Changeset.for_create(:create, %{
                         user_id: user.id,
                         provider: :facebook,
                         provider_id: same_id
                       })
                       |> Ash.create(actor: test_actor())

      # Create linked provider with Google using same ID (should work)
      {:ok, _linked2} = LinkedProvider
                       |> Ash.Changeset.for_create(:create, %{
                         user_id: user.id,
                         provider: :google,
                         provider_id: same_id
                       })
                       |> Ash.create(actor: test_actor())

      # Should have both linked providers
      linked_count = LinkedProvider
                    |> Ash.read!(actor: test_actor())
                    |> length()

      assert linked_count == 2
    end
  end

  describe "destroy action" do
    test "can remove linked provider" do
      # Create user and linked provider
      {:ok, user} = User
                   |> Ash.Changeset.for_create(:create_from_oauth, %{
                     email: "test_#{System.unique_integer([:positive])}@example.com",
                     provider: :x,
                     provider_id: "x123",
                     name: "Test User"
                   })
                   |> Ash.create(actor: test_actor())

      {:ok, linked_provider} = LinkedProvider
                               |> Ash.Changeset.for_create(:create, %{
                                 user_id: user.id,
                                 provider: :facebook,
                                 provider_id: "fb456"
                               })
                               |> Ash.create(actor: test_actor())

      # Remove the linked provider
      assert :ok = linked_provider
                   |> Ash.destroy(actor: test_actor())

      # Verify it's removed
      linked_providers = LinkedProvider
                        |> Ash.read!(actor: test_actor())

      assert length(linked_providers) == 0
    end
  end
end