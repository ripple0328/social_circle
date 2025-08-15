defmodule SocialCircleWeb.UserJourneys.AuthenticationJourneyTest do
  @moduledoc """
  End-to-end user journey tests for authentication flows using Ash Framework.
  
  This test suite covers the complete authentication user experience including:
  - Initial authentication with OAuth providers
  - Session management
  - Error handling scenarios
  - User creation and login with Ash actions
  """
  
  use SocialCircleWeb.ConnCase
  import Phoenix.LiveViewTest
  
  alias SocialCircle.Accounts.User

  describe "Primary authentication user journey" do
    test "user can navigate from home to auth page", %{conn: conn} do
      # Step 1: Visit landing page
      {:ok, _view, html} = live(conn, ~p"/")
      
      # Should see the landing page
      assert html =~ "Social Circle"
      assert html =~ "Get Started"
      
      # Step 2: Navigate to auth page
      {:ok, auth_view, auth_html} = live(conn, ~p"/auth")
      
      # Should see auth page content
      assert auth_html =~ "Unify Your Social Media Experience"
      assert auth_html =~ "Connect your accounts to get started"
      assert has_element?(auth_view, "button", "Continue with X")
      assert has_element?(auth_view, "button", "Continue with Facebook")
    end

    test "user can click auth button and get redirected to provider", %{conn: conn} do
      # Step 1: Navigate to auth page
      {:ok, auth_view, _auth_html} = live(conn, ~p"/auth")
      
      # Step 2: Click X auth button (should show loading state first)
      html_with_loading = auth_view
                          |> element("button", "Continue with X") 
                          |> render_click()
      
      assert html_with_loading =~ "Connecting"
      
      # The LiveView should redirect to /auth/x
      assert_redirect(auth_view, "/auth/x")
    end

    test "user can complete OAuth flow and access dashboard", %{conn: conn} do
      # Step 1: Simulate the complete OAuth flow
      conn = get(conn, ~p"/auth/x")
      
      # Should redirect to callback (our mock implementation)
      assert redirected_to(conn) =~ "/auth/x/callback"
      
      # Step 2: Follow redirect to callback
      conn = get(conn, redirected_to(conn))
      
      # Should redirect to dashboard with success message
      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully signed in with X"
      
      # Should have user_id in session
      user_id = get_session(conn, :user_id)
      assert user_id != nil
      
      # Step 3: Verify user was created in database
      user = User |> Ash.get!(user_id, actor: test_actor())
      assert user.email == "user@example.com"
      assert user.provider == :x
      assert user.name == "Test User"
    end

    test "user can access dashboard after authentication", %{conn: conn} do
      # Step 1: Create user and login session
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Access dashboard
      {:ok, dashboard_view, dashboard_html} = live(conn, ~p"/dashboard")
      
      assert dashboard_html =~ "Dashboard"
      assert dashboard_html =~ "Welcome to your social media dashboard"
      assert has_element?(dashboard_view, "a[href='/settings/accounts']")
    end

    test "authenticated user is redirected from auth page to dashboard", %{conn: conn} do
      # Step 1: Create user and login session
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Try to access auth page
      assert {:error, {:live_redirect, %{to: "/dashboard"}}} = live(conn, ~p"/auth")
    end

    test "unauthenticated user is redirected from protected pages to auth", %{conn: conn} do
      # Step 1: Try to access dashboard without authentication
      assert {:error, {:live_redirect, %{to: "/auth"}}} = live(conn, ~p"/dashboard")
      
      # Step 2: Try to access settings without authentication
      assert {:error, {:live_redirect, %{to: "/auth"}}} = live(conn, ~p"/settings/accounts")
    end
  end

  describe "Multiple provider authentication" do
    test "user can authenticate with different providers", %{conn: conn} do
      # Test X authentication
      conn = get(conn, ~p"/auth/x")
      conn = get(conn, redirected_to(conn))
      assert redirected_to(conn) == ~p"/dashboard"
      
      # Clear session and test Facebook
      conn = clear_session(conn)
      conn = get(conn, ~p"/auth/facebook")
      conn = get(conn, redirected_to(conn))
      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully signed in with Facebook"
    end

    test "same email with different provider creates separate session", %{conn: conn} do
      # First authentication with X
      conn = get(conn, ~p"/auth/x")
      conn = get(conn, redirected_to(conn))
      first_user_id = get_session(conn, :user_id)
      
      # Second authentication with Facebook (same email)
      conn = clear_session(conn)
      conn = get(conn, ~p"/auth/facebook")
      conn = get(conn, redirected_to(conn))
      second_user_id = get_session(conn, :user_id)
      
      # Should login the existing user (same email)
      assert first_user_id == second_user_id
    end
  end

  describe "Session management journey" do
    test "user can logout and session is cleared", %{conn: conn} do
      # Step 1: Create user and login session
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Verify user is logged in
      assert get_session(conn, :user_id) == user.id
      
      # Step 2: Logout
      conn = delete(conn, ~p"/auth/logout")
      
      # Should redirect to home page
      assert redirected_to(conn) == ~p"/"
      
      # Should have logout message
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "You have been signed out"
      
      # Session should be cleared
      assert get_session(conn, :user_id) == nil
    end
  end

  describe "Error handling scenarios" do
    test "user can handle OAuth errors gracefully", %{conn: conn} do
      # Step 1: Navigate to auth page with error parameter
      {:ok, auth_view, auth_html} = live(conn, ~p"/auth?error=access_denied")
      
      # Should display error message
      assert has_element?(auth_view, "[role='alert']")
      assert auth_html =~ "Authentication was cancelled"
      
      # Auth buttons should still be clickable
      assert has_element?(auth_view, "button", "Continue with X")
    end

    test "handles invalid provider gracefully", %{conn: conn} do
      # Try to access invalid provider
      conn = get(conn, ~p"/auth/invalid_provider")
      
      assert redirected_to(conn) == ~p"/auth"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid authentication provider"
    end

    test "handles OAuth callback errors", %{conn: conn} do
      # Simulate OAuth error callback
      conn = get(conn, ~p"/auth/x/callback?error=access_denied")
      
      assert redirected_to(conn) == ~p"/auth?error=access_denied"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Authentication was cancelled"
    end

    test "handles OAuth callback with missing code", %{conn: conn} do
      # Simulate callback without code parameter
      conn = get(conn, ~p"/auth/x/callback")
      
      assert redirected_to(conn) =~ "/auth?error=oauth_failed"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Authentication failed. Please try again."
    end
  end

  # Helper functions

  defp create_test_user(provider) do
    unique_id = System.unique_integer([:positive])
    User
    |> Ash.Changeset.for_create(:create_from_oauth, %{
      email: "test_#{unique_id}@example.com",
      provider: provider,
      provider_id: "#{provider}_test_#{unique_id}",
      name: "Test User",
      avatar_url: "https://example.com/avatar.jpg"
    })
    |> Ash.create(actor: test_actor())
  end
end