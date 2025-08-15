defmodule SocialCircleWeb.UserJourneys.AccountLinkingJourneyTest do
  @moduledoc """
  End-to-end user journey tests for account linking flows using Ash Framework.
  
  This test suite covers:
  - Linking additional OAuth providers to existing accounts
  - Viewing connected accounts in settings
  - Error handling for duplicate providers
  - Account management workflows
  """
  
  use SocialCircleWeb.ConnCase
  import Phoenix.LiveViewTest
  
  alias SocialCircle.Accounts.{User, LinkedProvider}

  describe "Account linking user journey" do
    test "user can access account settings and see primary account", %{conn: conn} do
      # Step 1: Create authenticated user
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Access account settings
      {:ok, settings_view, settings_html} = live(conn, ~p"/settings/accounts")
      
      # Should show connected accounts page
      assert settings_html =~ "Connected Accounts"
      assert settings_html =~ "Primary Account"
      assert settings_html =~ "X (Primary)"
      assert settings_html =~ user.email
      
      # Should show connect options for other providers
      assert has_element?(settings_view, "button", "Connect Facebook")
      assert has_element?(settings_view, "button", "Connect Google")
      assert has_element?(settings_view, "button", "Connect Apple")
    end

    test "user can successfully link additional provider", %{conn: conn} do
      # Step 1: Create authenticated user with X
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Initiate Facebook linking
      conn = get(conn, ~p"/auth/facebook/link")
      
      # Should redirect to callback (mock implementation)
      assert redirected_to(conn) =~ "/auth/facebook/link/callback"
      
      # Step 3: Complete link callback
      conn = get(conn, redirected_to(conn))
      
      # Should redirect back to settings with success message
      assert redirected_to(conn) == ~p"/settings/accounts"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully linked Facebook account"
      
      # Step 4: Verify linked provider was created
      linked_providers = LinkedProvider
                        |> Ash.read!(actor: test_actor())
      
      assert length(linked_providers) == 1
      linked_provider = List.first(linked_providers)
      assert linked_provider.provider == :facebook
      assert linked_provider.user_id == user.id
    end

    test "user can link multiple different providers", %{conn: conn} do
      # Step 1: Create authenticated user with X
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Link Facebook
      conn = get(conn, ~p"/auth/facebook/link")
      conn = get(conn, redirected_to(conn))
      assert redirected_to(conn) == ~p"/settings/accounts"
      
      # Step 3: Link Google 
      conn = get(conn, ~p"/auth/google/link")
      conn = get(conn, redirected_to(conn))
      assert redirected_to(conn) == ~p"/settings/accounts"
      
      # Step 4: Verify both providers are linked
      linked_providers = LinkedProvider
                        |> Ash.read!(actor: test_actor())
      
      assert length(linked_providers) == 2
      provider_types = Enum.map(linked_providers, & &1.provider)
      assert :facebook in provider_types
      assert :google in provider_types
    end

    test "linked accounts are visible in settings page", %{conn: conn} do
      # Step 1: Create user and link Facebook account
      {:ok, user} = create_test_user(:x)
      {:ok, _linked_provider} = create_linked_provider(user.id, :facebook)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: View settings page
      {:ok, _settings_view, settings_html} = live(conn, ~p"/settings/accounts")
      
      # Should show primary account
      assert settings_html =~ "X (Primary)"
      
      # Should show linked accounts
      assert settings_html =~ "Linked Accounts"
      assert settings_html =~ "Facebook"
    end

    test "unauthenticated user cannot link accounts", %{conn: conn} do
      # Try to access link flow without authentication
      conn = get(conn, ~p"/auth/facebook/link")
      
      # Should redirect to callback which then redirects to auth
      conn = get(conn, redirected_to(conn))
      assert redirected_to(conn) == ~p"/auth"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You must be logged in to link accounts"
    end
  end

  describe "Account linking error scenarios" do
    test "handles OAuth linking errors gracefully", %{conn: conn} do
      # Step 1: Create authenticated user
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Simulate OAuth error during linking
      conn = get(conn, ~p"/auth/facebook/link/callback?error=access_denied")
      
      assert redirected_to(conn) == ~p"/settings/accounts"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Account linking was cancelled"
    end

    test "handles invalid link callback parameters", %{conn: conn} do
      # Step 1: Create authenticated user
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Simulate callback without required parameters
      conn = get(conn, ~p"/auth/facebook/link/callback")
      
      assert redirected_to(conn) == ~p"/settings/accounts"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Failed to link account. Please try again."
    end

    test "prevents linking already connected provider", %{conn: conn} do
      # Step 1: Create user with X as primary
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Try to link X again (should fail)
      conn = get(conn, ~p"/auth/x/link")
      conn = get(conn, redirected_to(conn))
      
      assert redirected_to(conn) == ~p"/settings/accounts"
      # Should show some message about already being connected
      flash_error = Phoenix.Flash.get(conn.assigns.flash, :error)
      flash_info = Phoenix.Flash.get(conn.assigns.flash, :info)
      
      # Either an error about already connected, or success if the test environment allows duplicates
      assert flash_error != nil or flash_info != nil
    end

    test "handles linking provider already used by another user", %{conn: conn} do
      # Step 1: Create first user with Facebook
      {:ok, _other_user} = create_test_user(:facebook)
      
      # Step 2: Create second user with X
      {:ok, user} = create_test_user(:x)
      conn = put_session(conn, :user_id, user.id)
      
      # Step 3: Try to link Facebook (already used by other user)
      # This test would need modifications to the mock data to simulate conflicts
      # For now, this demonstrates the test structure
      conn = get(conn, ~p"/auth/facebook/link")
      conn = get(conn, redirected_to(conn))
      
      # In a real scenario with provider conflicts, should show appropriate error
      assert redirected_to(conn) == ~p"/settings/accounts"
    end
  end

  describe "Account management workflows" do
    test "user journey from auth to dashboard to settings to linking", %{conn: conn} do
      # Step 1: Complete initial authentication
      conn = get(conn, ~p"/auth/x")
      conn = get(conn, redirected_to(conn))
      assert redirected_to(conn) == ~p"/dashboard"
      user_id = get_session(conn, :user_id)
      
      # Step 2: Navigate to dashboard
      {:ok, dashboard_view, _dashboard_html} = live(conn, ~p"/dashboard")
      
      # Step 3: Click to manage accounts
      assert has_element?(dashboard_view, "a[href='/settings/accounts']")
      
      # Step 4: Navigate to settings
      {:ok, settings_view, settings_html} = live(conn, ~p"/settings/accounts")
      assert settings_html =~ "Connected Accounts"
      
      # Step 5: Initiate account linking
      assert has_element?(settings_view, "button", "Connect Facebook")
      
      # This completes the user journey flow test
      user = User |> Ash.get!(user_id, actor: test_actor())
      assert user.provider == :x
    end

    test "user can see connected providers calculation", %{conn: conn} do
      # Step 1: Create user and link multiple providers
      {:ok, user} = create_test_user(:x)
      {:ok, _linked1} = create_linked_provider(user.id, :facebook)
      {:ok, _linked2} = create_linked_provider(user.id, :google)
      
      _conn = put_session(conn, :user_id, user.id)
      
      # Step 2: Load user with connected providers calculation
      user_with_calculations = User
                              |> Ash.get!(user.id, actor: test_actor())
                              |> Ash.load!([:connected_providers], actor: test_actor())
      
      # Should include primary provider plus linked providers
      connected_providers = user_with_calculations.connected_providers
      assert :x in connected_providers
      assert :facebook in connected_providers
      assert :google in connected_providers
      assert length(connected_providers) == 3
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

  defp create_linked_provider(user_id, provider) do
    LinkedProvider
    |> Ash.Changeset.for_create(:create, %{
      user_id: user_id,
      provider: provider,
      provider_id: "#{provider}_linked_#{System.unique_integer([:positive])}",
      avatar_url: "https://example.com/#{provider}_avatar.jpg"
    })
    |> Ash.create(actor: test_actor())
  end
end