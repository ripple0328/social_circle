defmodule SocialCircleWeb.AuthControllerTest do
  use SocialCircleWeb.ConnCase

  import SocialCircle.AccountsFixtures

  describe "OAuth initiation" do
    test "GET /auth/:provider redirects to OAuth provider", %{conn: conn} do
      conn = get(conn, ~p"/auth/x")
      
      # Should redirect to X OAuth URL
      assert redirected_to(conn) =~ "api.twitter.com/oauth"
      assert get_flash(conn, :info) == nil
    end

    test "GET /auth/:provider handles invalid provider", %{conn: conn} do
      conn = get(conn, ~p"/auth/invalid_provider")
      
      assert redirected_to(conn) == ~p"/auth"
      assert get_flash(conn, :error) == "Invalid authentication provider"
    end
  end

  describe "OAuth callback handling" do
    test "GET /auth/:provider/callback with valid X response creates user", %{conn: conn} do
      # Mock OAuth response data
      oauth_response = %{
        "provider" => "x",
        "uid" => "123456789",
        "info" => %{
          "email" => "newuser@example.com",
          "name" => "New User",
          "image" => "https://pbs.twimg.com/profile_images/123/avatar.jpg"
        },
        "extra" => %{
          "raw_info" => %{
            "user" => %{
              "id" => "123456789",
              "username" => "newuser",
              "name" => "New User"
            }
          }
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/x/callback")

      # Should create user and redirect to dashboard
      assert redirected_to(conn) == ~p"/dashboard"
      assert get_flash(conn, :info) == "Successfully signed in with X"

      # Verify user was created
      assert {:ok, [user]} = 
        SocialCircle.Accounts.User
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(email: "newuser@example.com")
        |> Ash.read()

      assert user.provider == :x
      assert user.provider_id == "123456789"
    end

    test "GET /auth/:provider/callback with existing user signs them in", %{conn: conn} do
      # Create existing user
      existing_user = user_fixture(%{
        email: "existing@example.com",
        provider: :x,
        provider_id: "existing123"
      })

      oauth_response = %{
        "provider" => "x",
        "uid" => "existing123",
        "info" => %{
          "email" => "existing@example.com",
          "name" => "Existing User"
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/x/callback")

      # Should sign in existing user
      assert redirected_to(conn) == ~p"/dashboard"
      assert get_flash(conn, :info) == "Welcome back!"

      # Should be the same user, not a new one
      assert get_session(conn, :user_id) == existing_user.id
    end

    test "GET /auth/:provider/callback handles OAuth errors", %{conn: conn} do
      oauth_error = %{
        "provider" => "x",
        "strategy" => "twitter"
      }

      conn = 
        conn
        |> assign(:ueberauth_failure, oauth_error)
        |> get(~p"/auth/x/callback")

      assert redirected_to(conn) == ~p"/auth?error=oauth_failed"
      assert get_flash(conn, :error) == "Authentication failed. Please try again."
    end

    test "GET /auth/:provider/callback with missing email handles gracefully", %{conn: conn} do
      oauth_response = %{
        "provider" => "x",
        "uid" => "123456789",
        "info" => %{
          "name" => "User Without Email"
          # email is missing
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/x/callback")

      assert redirected_to(conn) == ~p"/auth?error=missing_email"
      assert get_flash(conn, :error) == "Email address is required for authentication"
    end

    test "handles duplicate provider_id gracefully", %{conn: conn} do
      # Create user with specific provider_id
      _existing_user = user_fixture(%{
        email: "first@example.com",
        provider: :x,
        provider_id: "duplicate123"
      })

      # Try to create another user with same provider_id but different email
      oauth_response = %{
        "provider" => "x",
        "uid" => "duplicate123",
        "info" => %{
          "email" => "second@example.com",
          "name" => "Second User"
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/x/callback")

      # Should sign in the existing user, not create new one
      assert redirected_to(conn) == ~p"/dashboard"
      assert get_flash(conn, :info) == "Welcome back!"
    end
  end

  describe "account linking flow" do
    setup %{conn: conn} do
      user = user_fixture(%{
        provider: :x,
        provider_id: "x123",
        email: "main@example.com"
      })
      
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "GET /auth/:provider/link initiates linking flow", %{conn: conn} do
      conn = get(conn, ~p"/auth/google/link")
      
      # Should redirect to Google OAuth with linking state
      assert redirected_to(conn) =~ "accounts.google.com/oauth"
      assert get_session(conn, :linking_account) == true
    end

    test "GET /auth/:provider/link/callback links additional provider", %{conn: conn, user: user} do
      # Set linking state
      conn = put_session(conn, :linking_account, true)

      oauth_response = %{
        "provider" => "google",
        "uid" => "google456",
        "info" => %{
          "email" => "same@example.com",  # Same email
          "name" => "Same User"
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/google/link/callback")

      assert redirected_to(conn) == ~p"/settings/accounts"
      assert get_flash(conn, :info) == "Google account linked successfully"

      # Verify provider was linked
      updated_user = Ash.reload!(user)
      updated_user = Ash.load!(updated_user, :linked_providers)
      
      assert length(updated_user.linked_providers) == 1
      linked_provider = hd(updated_user.linked_providers)
      assert linked_provider.provider == :google
      assert linked_provider.provider_id == "google456"
    end

    test "prevents linking provider already used by another user", %{conn: conn} do
      # Create another user with Google
      _other_user = user_fixture(%{
        email: "other@example.com",
        provider: :google,
        provider_id: "google789"
      })

      conn = put_session(conn, :linking_account, true)

      oauth_response = %{
        "provider" => "google",
        "uid" => "google789",  # Same provider_id as other user
        "info" => %{
          "email" => "different@example.com",
          "name" => "Different User"
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/google/link/callback")

      assert redirected_to(conn) == ~p"/settings/accounts"
      assert get_flash(conn, :error) == "This Google account is already connected to another user"
    end
  end

  describe "session management" do
    test "DELETE /auth/logout signs out user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Verify user is signed in
      assert get_session(conn, :user_id) == user.id

      # Sign out
      conn = delete(conn, ~p"/auth/logout")

      assert redirected_to(conn) == ~p"/"
      assert get_flash(conn, :info) == "You have been signed out"
      assert get_session(conn, :user_id) == nil
    end

    test "POST /auth/refresh_tokens refreshes OAuth tokens", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      conn = post(conn, ~p"/auth/refresh_tokens")

      assert redirected_to(conn) == ~p"/settings/accounts"
      assert get_flash(conn, :info) == "Account connections refreshed"
    end
  end

  describe "provider-specific features" do
    test "handles X-specific data extraction", %{conn: conn} do
      oauth_response = %{
        "provider" => "x",
        "uid" => "x123",
        "info" => %{
          "email" => "xuser@example.com",
          "name" => "X User",
          "nickname" => "xuser"
        },
        "extra" => %{
          "raw_info" => %{
            "user" => %{
              "id" => "x123",
              "username" => "xuser",
              "verified" => true,
              "followers_count" => 1000
            }
          }
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/x/callback")

      # Verify X-specific data is stored
      assert {:ok, [user]} = 
        SocialCircle.Accounts.User
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(email: "xuser@example.com")
        |> Ash.read()

      assert user.raw_data["username"] == "xuser"
      assert user.raw_data["verified"] == true
      assert user.raw_data["followers_count"] == 1000
    end

    test "handles Apple Sign-In privacy features", %{conn: conn} do
      oauth_response = %{
        "provider" => "apple",
        "uid" => "apple123.privaterelay",
        "info" => %{
          "email" => "privaterelay@privaterelay.appleid.com",
          "name" => "Apple User"
        },
        "extra" => %{
          "raw_info" => %{
            "is_private_email" => true,
            "real_user_status" => 1
          }
        }
      }

      conn = 
        conn
        |> assign(:ueberauth_auth, oauth_response)
        |> get(~p"/auth/apple/callback")

      # Verify Apple privacy features are handled
      assert {:ok, [user]} = 
        SocialCircle.Accounts.User
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(provider_id: "apple123.privaterelay")
        |> Ash.read()

      assert user.raw_data["is_private_email"] == true
      assert user.avatar_url == nil  # Apple doesn't provide avatars
    end
  end
end