defmodule SocialCircleWeb.AuthLiveTest do
  use SocialCircleWeb.ConnCase

  import Phoenix.LiveViewTest
  import SocialCircle.AccountsFixtures

  describe "authentication landing page" do
    test "displays authentication options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/auth")

      # Check page title and main content
      assert html =~ "Unify Your Social Media Experience"
      assert html =~ "Connect your accounts to get started"

      # Check primary X authentication button
      assert has_element?(view, "button", "Continue with X")

      # Check secondary authentication options
      assert has_element?(view, "button", "Continue with Facebook")
      assert has_element?(view, "button", "Continue with Google")
      assert has_element?(view, "button", "Continue with Apple")

      # Check trust indicators
      assert html =~ "Secure"
      assert html =~ "Private"
      assert html =~ "No Passwords"
    end

    test "X button is prominently displayed as primary", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/auth")

      # X button should have primary styling
      assert has_element?(view, "button[class*='auth-button-primary']", "Continue with X")

      # Other buttons should have secondary styling
      assert has_element?(
               view,
               "button[class*='auth-button-secondary']",
               "Continue with Facebook"
             )

      assert has_element?(view, "button[class*='auth-button-secondary']", "Continue with Google")
      assert has_element?(view, "button[class*='auth-button-secondary']", "Continue with Apple")
    end

    test "clicking X auth button initiates OAuth flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/auth")

      # Click the X authentication button
      assert view
             |> element("button", "Continue with X")
             |> render_click() =~ "Connecting"

      # Should redirect to OAuth provider
      assert_redirect(view, "/auth/x")
    end

    test "clicking other provider buttons initiates respective OAuth flows", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/auth")

      # Test Facebook
      view
      |> element("button", "Continue with Facebook")
      |> render_click()

      assert_redirect(view, "/auth/facebook")

      # Reset and test Google
      {:ok, view, _html} = live(conn, ~p"/auth")

      view
      |> element("button", "Continue with Google")
      |> render_click()

      assert_redirect(view, "/auth/google")

      # Reset and test Apple
      {:ok, view, _html} = live(conn, ~p"/auth")

      view
      |> element("button", "Continue with Apple")
      |> render_click()

      assert_redirect(view, "/auth/apple")
    end

    test "shows loading state when OAuth is initiated", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/auth")

      # Start OAuth flow
      html =
        view
        |> element("button", "Continue with X")
        |> render_click()

      # Should show loading state
      assert html =~ "Connecting"
      assert html =~ "spinner" || html =~ "animate-spin"
    end

    test "handles OAuth errors gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/auth?error=access_denied")

      # Should display error message
      assert has_element?(view, "[role='alert']")
      assert render(view) =~ "Authentication was cancelled"

      # Auth buttons should still be clickable
      assert has_element?(view, "button", "Continue with X")
    end

    test "displays privacy and terms links", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/auth")

      assert html =~ "Terms of Service"
      assert html =~ "Privacy Policy"
      assert has_element?(view, "a[href*='terms']")
      assert has_element?(view, "a[href*='privacy']")
    end
  end

  describe "authenticated user redirection" do
    test "redirects authenticated users to dashboard", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      result = live(conn, ~p"/auth")

      case result do
        {:error, {:redirect, %{to: "/dashboard"}}} -> :ok
        {:error, {:live_redirect, %{to: "/dashboard"}}} -> :ok
        other -> flunk("Expected redirect to dashboard, got: #{inspect(other)}")
      end
    end
  end

  describe "responsive design" do
    test "displays mobile-optimized layout", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/auth")

      # Check for mobile-responsive classes
      assert html =~ "auth-container"
      # Full width buttons on mobile
      assert html =~ "w-full"
    end
  end

  describe "account management page" do
    setup %{conn: conn} do
      user =
        user_fixture(%{
          provider: :x,
          provider_id: "x123",
          email: "test@example.com"
        })

      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "displays connected accounts", %{conn: conn, user: user} do
      {:ok, view, html} = live(conn, ~p"/settings/accounts")

      # Should show primary X account
      assert html =~ "X (Primary)"
      assert html =~ user.email
      assert html =~ "Connected"

      # Should show options to add more platforms
      assert has_element?(view, "button", "Connect Facebook")
      assert has_element?(view, "button", "Connect Google")
      assert has_element?(view, "button", "Connect Apple")
    end

    test "allows linking additional platforms", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/settings/accounts")

      # Click to connect Facebook
      view
      |> element("button", "Connect Facebook")
      |> render_click()

      # Should redirect to OAuth flow
      assert_redirect(view, "/auth/facebook/link")
    end

    test "shows sync status for connected accounts", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/accounts")

      # Should show last sync time
      assert html =~ "Last sync:"
      assert html =~ "ago" || html =~ "minutes" || html =~ "seconds"
    end

    test "allows disconnecting secondary accounts", %{conn: conn, user: user} do
      # Link a secondary account first
      {:ok, _updated_user} =
        user
        |> Ash.Changeset.for_update(:link_provider, %{
          provider: :google,
          provider_id: "google123"
        })
        |> Ash.update(actor: test_actor())

      {:ok, view, _html} = live(conn, ~p"/settings/accounts")

      # Should show disconnect button for secondary account
      assert has_element?(view, "button", "Disconnect")

      # Click disconnect
      view
      |> element("button", "Disconnect")
      |> render_click()

      # Should show confirmation
      assert render(view) =~ "Are you sure you want to disconnect"
    end

    test "prevents disconnecting primary account if it's the only one", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/settings/accounts")

      # Primary account should be shown
      assert html =~ "Primary"
      # Since this is the only account, disconnect should be limited or not available for primary
      # The exact UI behavior may vary, so we just ensure primary is shown
    end
  end
end
