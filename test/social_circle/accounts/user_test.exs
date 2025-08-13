defmodule SocialCircle.Accounts.UserTest do
  use SocialCircle.DataCase

  alias SocialCircle.Accounts.User

  describe "create_from_oauth action" do
    test "creates user with valid X OAuth data" do
      oauth_data = %{
        email: "test@example.com",
        provider: :x,
        provider_id: "123456789",
        name: "Test User",
        avatar_url: "https://pbs.twimg.com/profile_images/123/avatar.jpg",
        raw_data: %{
          "id" => "123456789",
          "username" => "testuser",
          "name" => "Test User"
        }
      }

      assert {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()

      assert user.email == "test@example.com"
      assert user.provider == :x
      assert user.provider_id == "123456789"
      assert user.name == "Test User"
      assert user.avatar_url == "https://pbs.twimg.com/profile_images/123/avatar.jpg"
    end

    test "creates user with valid Facebook OAuth data" do
      oauth_data = %{
        email: "facebook@example.com",
        provider: :facebook,
        provider_id: "fb123456789",
        name: "Facebook User",
        avatar_url: "https://graph.facebook.com/123/picture"
      }

      assert {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()

      assert user.provider == :facebook
      assert user.provider_id == "fb123456789"
    end

    test "creates user with valid Google OAuth data" do
      oauth_data = %{
        email: "google@example.com",
        provider: :google,
        provider_id: "google123456789",
        name: "Google User",
        avatar_url: "https://lh3.googleusercontent.com/a/avatar"
      }

      assert {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()

      assert user.provider == :google
      assert user.provider_id == "google123456789"
    end

    test "creates user with valid Apple OAuth data" do
      oauth_data = %{
        email: "apple@example.com",
        provider: :apple,
        provider_id: "apple123456789",
        name: "Apple User"
        # Apple doesn't provide avatar URLs
      }

      assert {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()

      assert user.provider == :apple
      assert user.provider_id == "apple123456789"
      assert is_nil(user.avatar_url)
    end

    test "fails with missing required fields" do
      oauth_data = %{
        provider: :x,
        provider_id: "123456789"
        # missing email
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()
    end

    test "fails with invalid provider" do
      oauth_data = %{
        email: "test@example.com",
        provider: :invalid_provider,
        provider_id: "123456789"
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()
    end

    test "fails with invalid email format" do
      oauth_data = %{
        email: "invalid-email",
        provider: :x,
        provider_id: "123456789"
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()
    end

    test "prevents duplicate email addresses" do
      oauth_data = %{
        email: "duplicate@example.com",
        provider: :x,
        provider_id: "123456789",
        name: "First User"
      }

      # Create first user
      assert {:ok, _user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()

      # Try to create second user with same email but different provider
      duplicate_data = %{oauth_data | provider: :google, provider_id: "google123"}

      assert {:error, %Ash.Error.Invalid{}} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, duplicate_data)
        |> Ash.create()
    end

    test "prevents duplicate provider + provider_id combination" do
      oauth_data = %{
        email: "test1@example.com",
        provider: :x,
        provider_id: "123456789",
        name: "First User"
      }

      # Create first user
      assert {:ok, _user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, oauth_data)
        |> Ash.create()

      # Try to create second user with same provider + provider_id but different email
      duplicate_data = %{oauth_data | email: "test2@example.com"}

      assert {:error, %Ash.Error.Invalid{}} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, duplicate_data)
        |> Ash.create()
    end
  end

  describe "link_provider action" do
    test "links additional provider to existing user" do
      # Create user with X
      {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "test@example.com",
          provider: :x,
          provider_id: "x123",
          name: "Test User"
        })
        |> Ash.create()

      # Link Google account
      google_data = %{
        provider: :google,
        provider_id: "google123",
        avatar_url: "https://lh3.googleusercontent.com/avatar"
      }

      assert {:ok, updated_user} = 
        user
        |> Ash.Changeset.for_update(:link_provider, google_data)
        |> Ash.update()

      # Verify linked providers are stored
      assert length(updated_user.linked_providers) == 1
      linked_provider = hd(updated_user.linked_providers)
      assert linked_provider.provider == :google
      assert linked_provider.provider_id == "google123"
    end

    test "fails to link provider if already linked elsewhere" do
      # Create first user with X
      {:ok, user1} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "user1@example.com",
          provider: :x,
          provider_id: "x123"
        })
        |> Ash.create()

      # Create second user with Google
      {:ok, user2} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "user2@example.com",
          provider: :google,
          provider_id: "google123"
        })
        |> Ash.create()

      # Try to link Google account that's already primary for user2 to user1
      google_data = %{
        provider: :google,
        provider_id: "google123"
      }

      assert {:error, %Ash.Error.Invalid{}} = 
        user1
        |> Ash.Changeset.for_update(:link_provider, google_data)
        |> Ash.update()
    end
  end

  describe "find_or_create_from_oauth action" do
    test "finds existing user by email" do
      # Create user
      {:ok, existing_user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "existing@example.com",
          provider: :x,
          provider_id: "x123",
          name: "Existing User"
        })
        |> Ash.create()

      # Try to create again with different provider but same email
      oauth_data = %{
        email: "existing@example.com",
        provider: :google,
        provider_id: "google123",
        name: "Same User"
      }

      assert {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:find_or_create_from_oauth, oauth_data)
        |> Ash.create()

      # Should return existing user, not create new one
      assert user.id == existing_user.id
      assert user.name == "Existing User"  # Keeps original name
    end

    test "creates new user if none exists" do
      oauth_data = %{
        email: "new@example.com",
        provider: :x,
        provider_id: "x456",
        name: "New User"
      }

      assert {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:find_or_create_from_oauth, oauth_data)
        |> Ash.create()

      assert user.email == "new@example.com"
      assert user.name == "New User"
    end
  end

  describe "policies" do
    test "users can read their own data" do
      {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "owner@example.com",
          provider: :x,
          provider_id: "x123"
        })
        |> Ash.create()

      assert {:ok, [found_user]} = 
        User
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(id: user.id)
        |> Ash.read(actor: user)

      assert found_user.id == user.id
    end

    test "users cannot read other users' data" do
      {:ok, user1} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "user1@example.com",
          provider: :x,
          provider_id: "x123"
        })
        |> Ash.create()

      {:ok, user2} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "user2@example.com",
          provider: :google,
          provider_id: "google123"
        })
        |> Ash.create()

      # User1 tries to read User2's data
      assert {:ok, []} = 
        User
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(id: user2.id)
        |> Ash.read(actor: user1)
    end

    test "users can update their own profile" do
      {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "updater@example.com",
          provider: :x,
          provider_id: "x123",
          name: "Original Name"
        })
        |> Ash.create()

      assert {:ok, updated_user} = 
        user
        |> Ash.Changeset.for_update(:update_profile, %{name: "Updated Name"}, actor: user)
        |> Ash.update()

      assert updated_user.name == "Updated Name"
    end

    test "users cannot update other users' profiles" do
      {:ok, user1} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "user1@example.com",
          provider: :x,
          provider_id: "x123"
        })
        |> Ash.create()

      {:ok, user2} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "user2@example.com",
          provider: :google,
          provider_id: "google123"
        })
        |> Ash.create()

      # User1 tries to update User2's profile
      assert {:error, %Ash.Error.Forbidden{}} = 
        user2
        |> Ash.Changeset.for_update(:update_profile, %{name: "Hacked Name"}, actor: user1)
        |> Ash.update()
    end
  end

  describe "calculations" do
    test "primary_provider calculation returns main provider" do
      {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "calc@example.com",
          provider: :x,
          provider_id: "x123"
        })
        |> Ash.create()

      user = Ash.load!(user, :primary_provider)
      assert user.primary_provider == :x
    end

    test "connected_providers calculation lists all providers" do
      {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create_from_oauth, %{
          email: "multi@example.com",
          provider: :x,
          provider_id: "x123"
        })
        |> Ash.create()

      # Link additional provider
      {:ok, user} = 
        user
        |> Ash.Changeset.for_update(:link_provider, %{
          provider: :google,
          provider_id: "google123"
        })
        |> Ash.update()

      user = Ash.load!(user, :connected_providers)
      assert :x in user.connected_providers
      assert :google in user.connected_providers
    end
  end
end