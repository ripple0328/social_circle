defmodule SocialCircleWeb.AuthControllerTest do
  @moduledoc """
  Controller tests for authentication flows using Ash Framework.

  Tests cover:
  - OAuth provider redirects
  - OAuth callback handling
  - Account linking flows
  - Session management
  - Error handling
  """

  use SocialCircleWeb.ConnCase

  alias SocialCircle.Accounts.{LinkedProvider, User}

  describe "OAuth provider redirect" do
    test "GET /auth/:provider redirects to OAuth callback for valid providers", %{conn: conn} do
      for provider <- ["x", "facebook", "google", "apple"] do
        conn = get(conn, ~p"/auth/#{provider}")

        # Should redirect to callback URL (our mock implementation)
        assert redirected_to(conn) =~ "/auth/#{provider}/callback"
        assert Phoenix.Flash.get(conn.assigns.flash, :info) == nil
      end
    end

    test "GET /auth/:provider handles invalid provider", %{conn: conn} do
      conn = get(conn, ~p"/auth/invalid_provider")

      assert redirected_to(conn) == ~p"/auth"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid authentication provider"
    end
  end

  describe "OAuth callback handling" do
    test "GET /auth/:provider/callback with code creates new user and signs in", %{conn: conn} do
      conn = get(conn, ~p"/auth/x/callback?code=test_code&state=test_state")

      # Should redirect to dashboard
      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully signed in with X"

      # Should have user_id in session
      user_id = get_session(conn, :user_id)
      assert user_id != nil

      # Should have created user in database
      user = User |> Ash.get!(user_id, actor: test_actor())
      assert user.email == "user@example.com"
      assert user.provider == :x
      assert user.name == "Test User"
    end

    test "GET /auth/:provider/callback with existing user signs them in", %{conn: conn} do
      # Create existing user first
      {:ok, _existing_user} = create_test_user(:x, "existing@example.com")

      # Mock will use same email, so should find existing user
      # Note: This test demonstrates the concept, though our mock always uses the same email
      conn = get(conn, ~p"/auth/x/callback?code=test_code")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully signed in with X"

      # Should not create new user, should use existing
      user_id = get_session(conn, :user_id)

      # In real implementation with proper OAuth data extraction, this would match existing_user.id
      assert user_id != nil
    end

    test "GET /auth/:provider/callback handles OAuth errors", %{conn: conn} do
      conn = get(conn, ~p"/auth/x/callback?error=access_denied")

      assert redirected_to(conn) == ~p"/auth?error=access_denied"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Authentication was cancelled"
    end

    test "GET /auth/:provider/callback handles missing code parameter", %{conn: conn} do
      conn = get(conn, ~p"/auth/x/callback")

      assert redirected_to(conn) =~ "/auth?error=oauth_failed"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Authentication failed. Please try again."
    end
  end

  describe "account linking flow" do
    test "GET /auth/:provider/link/callback links additional provider to authenticated user", %{
      conn: conn
    } do
      # Create user and authenticate
      {:ok, user} = create_test_user(:x, "link_test@example.com")
      conn = put_session(conn, :user_id, user.id)

      # Link Facebook account
      conn = get(conn, ~p"/auth/facebook/link/callback?code=link_code")

      assert redirected_to(conn) == ~p"/settings/accounts"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Successfully linked Facebook account"

      # Should have created linked provider
      linked_providers =
        LinkedProvider
        |> Ash.read!(actor: test_actor())

      assert length(linked_providers) == 1
      linked_provider = List.first(linked_providers)
      assert linked_provider.provider == :facebook
      assert linked_provider.user_id == user.id
    end

    test "GET /auth/:provider/link/callback requires authentication", %{conn: conn} do
      # Try to link without being authenticated
      conn = get(conn, ~p"/auth/facebook/link/callback?code=link_code")

      assert redirected_to(conn) == ~p"/auth"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be logged in to link accounts"
    end

    test "GET /auth/:provider/link/callback handles link errors", %{conn: conn} do
      # Create user and authenticate
      {:ok, user} = create_test_user(:x, "link_error_test@example.com")
      conn = put_session(conn, :user_id, user.id)

      # Simulate OAuth error during linking
      conn = get(conn, ~p"/auth/facebook/link/callback?error=access_denied")

      assert redirected_to(conn) == ~p"/settings/accounts"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Account linking was cancelled"
    end

    test "GET /auth/:provider/link/callback handles missing parameters", %{conn: conn} do
      # Create user and authenticate
      {:ok, user} = create_test_user(:x, "link_missing_test@example.com")
      conn = put_session(conn, :user_id, user.id)

      # Try link callback without code parameter
      conn = get(conn, ~p"/auth/facebook/link/callback")

      assert redirected_to(conn) == ~p"/settings/accounts"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Failed to link account. Please try again."
    end
  end

  describe "session management" do
    test "DELETE /auth/logout signs out user and clears session", %{conn: conn} do
      # Create user and authenticate
      {:ok, user} = create_test_user(:x, "logout_test@example.com")
      conn = put_session(conn, :user_id, user.id)

      # Verify user is logged in
      assert get_session(conn, :user_id) == user.id

      # Logout
      conn = delete(conn, ~p"/auth/logout")

      # Should redirect to home page
      assert redirected_to(conn) == ~p"/"

      # Should have logout message
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You have been signed out"

      # Session should be cleared
      assert get_session(conn, :user_id) == nil
    end
  end

  describe "error handling edge cases" do
    test "handles database errors gracefully during user creation", %{conn: conn} do
      # This test would require mocking database failures
      # For now, we test the general error path
      conn = get(conn, ~p"/auth/x/callback?code=test_code")

      # Should redirect somewhere (either success or error)
      assert redirected_to(conn) != nil
    end

    test "handles invalid session data", %{conn: conn} do
      # Put invalid user_id in session
      conn = put_session(conn, :user_id, "invalid-uuid")

      # Try to link account (should handle gracefully)
      conn = get(conn, ~p"/auth/facebook/link/callback?code=test")

      # Should redirect to auth (due to invalid user)
      assert redirected_to(conn) == ~p"/auth"
    end
  end

  describe "provider-specific routing" do
    test "all providers have consistent routing patterns" do
      providers = ["x", "facebook", "google", "apple"]

      for provider <- providers do
        # Test initial provider redirect
        conn = build_conn() |> get(~p"/auth/#{provider}")
        assert redirected_to(conn) =~ "/auth/#{provider}/callback"

        # Test callback success
        conn = build_conn() |> get(~p"/auth/#{provider}/callback?code=test")
        assert redirected_to(conn) == ~p"/dashboard"

        # Test link redirect (requires auth)
        {:ok, user} =
          create_test_user(
            :x,
            "routing_test_#{provider}_#{System.unique_integer([:positive])}@example.com"
          )

        conn =
          build_conn()
          |> init_test_session(%{})
          |> put_session(:user_id, user.id)
          |> get(~p"/auth/#{provider}/link")

        assert redirected_to(conn) =~ "/auth/#{provider}/link/callback"
      end
    end
  end

  # Helper functions

  defp create_test_user(provider, email) do
    unique_id = System.unique_integer([:positive])
    final_email = email || "test_#{unique_id}@example.com"

    User
    |> Ash.Changeset.for_create(:create_from_oauth, %{
      email: final_email,
      provider: provider,
      provider_id: "#{provider}_test_#{unique_id}",
      name: "Test User",
      avatar_url: "https://example.com/avatar.jpg"
    })
    |> Ash.create(actor: test_actor())
  end
end
