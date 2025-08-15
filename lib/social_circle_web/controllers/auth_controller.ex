defmodule SocialCircleWeb.AuthController do
  @moduledoc """
  AuthController for handling OAuth authentication flows using Ash Framework.

  This controller handles:
  - OAuth provider redirects
  - OAuth callbacks  
  - Account linking
  - Session management
  """

  use SocialCircleWeb, :controller

  alias SocialCircle.Accounts.User

  @doc """
  Redirect to OAuth provider for authentication
  """
  def provider(conn, %{"provider" => provider})
      when provider in ["x", "facebook", "google", "apple"] do
    # For now, simulate OAuth by redirecting to callback with test data
    # In production, this would redirect to the actual OAuth provider

    # Check if this is a link request (from /auth/:provider/link route)
    request_path = conn.request_path

    test_redirect_url =
      if String.contains?(request_path, "/link") do
        url(~p"/auth/#{provider}/link/callback?code=test_code&state=test_state")
      else
        url(~p"/auth/#{provider}/callback?code=test_code&state=test_state")
      end

    redirect(conn, external: test_redirect_url)
  end

  def provider(conn, _params) do
    conn
    |> put_flash(:error, "Invalid authentication provider")
    |> redirect(to: ~p"/auth")
  end

  @doc """
  Handle OAuth callback and create/login user
  """
  def callback(conn, %{"provider" => provider} = params)
      when provider in ["x", "facebook", "google", "apple"] do
    case params do
      %{"code" => _code} -> handle_successful_callback(conn, provider, params)
      %{"error" => error} -> handle_error_callback(conn, error)
      _ -> handle_error_callback(conn, "invalid_request")
    end
  end

  @doc """
  Link additional provider to existing user account
  """
  def link_callback(conn, %{"provider" => provider} = params)
      when provider in ["x", "facebook", "google", "apple"] do
    current_user_id = get_session(conn, :user_id)

    if current_user_id do
      case params do
        %{"code" => _code} -> handle_link_provider(conn, current_user_id, provider, params)
        %{"error" => error} -> handle_link_error(conn, error)
        _ -> handle_link_error(conn, "invalid_request")
      end
    else
      conn
      |> put_flash(:error, "You must be logged in to link accounts")
      |> redirect(to: ~p"/auth")
    end
  end

  @doc """
  Sign out user and clear session
  """
  def logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: ~p"/")
  end

  # Private helper functions

  defp handle_successful_callback(conn, provider, _params) do
    # Extract user info from OAuth response (simulated for now)
    oauth_user_info = get_mock_oauth_user_info(provider)

    case find_or_create_user(oauth_user_info) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Successfully signed in with #{String.capitalize(provider)}")
        |> redirect(to: ~p"/dashboard")

      {:error, %Ash.Error.Invalid{} = error} ->
        error_message = get_readable_error_message(error)

        conn
        |> put_flash(:error, error_message)
        |> redirect(to: ~p"/auth?error=oauth_failed")

      {:error, _error} ->
        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: ~p"/auth?error=oauth_failed")
    end
  end

  defp handle_error_callback(conn, error) do
    error_param =
      case error do
        "access_denied" -> "access_denied"
        _ -> "oauth_failed"
      end

    conn
    |> put_flash(:error, get_error_message(error_param))
    |> redirect(to: ~p"/auth?error=#{error_param}")
  end

  defp handle_link_provider(conn, user_id, provider, _params) do
    # Extract provider info from OAuth response (simulated for now)
    oauth_info = get_mock_oauth_user_info(provider)

    # Create actor for authorization
    actor = %{test_env: true, id: user_id}

    # Handle invalid UUID gracefully
    with {:ok, user} <- get_user_safely(user_id, actor) do
      case user
           |> Ash.Changeset.for_update(:link_provider, %{
             provider: String.to_atom(provider),
             provider_id: oauth_info[:provider_id],
             avatar_url: oauth_info[:avatar_url]
           })
           |> Ash.update(actor: actor) do
        {:ok, _user} ->
          conn
          |> put_flash(:info, "Successfully linked #{String.capitalize(provider)} account")
          |> redirect(to: ~p"/settings/accounts")

        {:error, %Ash.Error.Invalid{} = error} ->
          error_message = get_readable_error_message(error)

          conn
          |> put_flash(:error, error_message)
          |> redirect(to: ~p"/settings/accounts")

        {:error, _error} ->
          conn
          |> put_flash(:error, "Failed to link account. Please try again.")
          |> redirect(to: ~p"/settings/accounts")
      end
    else
      _ ->
        conn
        |> put_flash(:error, "You must be logged in to link accounts")
        |> redirect(to: ~p"/auth")
    end
  end

  defp get_user_safely(user_id, actor) do
    try do
      user = User |> Ash.get!(user_id, actor: actor)
      {:ok, user}
    rescue
      _ -> {:error, :invalid_user}
    end
  end

  defp handle_link_error(conn, error) do
    error_message =
      case error do
        "access_denied" -> "Account linking was cancelled"
        _ -> "Failed to link account. Please try again."
      end

    conn
    |> put_flash(:error, error_message)
    |> redirect(to: ~p"/settings/accounts")
  end

  defp find_or_create_user(oauth_info) do
    # Use the find_or_create_from_oauth action which handles this logic
    User
    |> Ash.Changeset.for_create(:find_or_create_from_oauth, %{
      email: oauth_info[:email],
      provider: oauth_info[:provider],
      provider_id: oauth_info[:provider_id],
      name: oauth_info[:name],
      avatar_url: oauth_info[:avatar_url],
      raw_data: oauth_info[:raw_data]
    })
    |> Ash.create()
  end

  # Mock OAuth user info for testing
  # In production, this would extract real data from OAuth provider response
  defp get_mock_oauth_user_info("x") do
    [
      email: "user@example.com",
      provider: :x,
      provider_id: "x_#{System.unique_integer([:positive])}",
      name: "Test User",
      avatar_url: "https://example.com/avatar.jpg",
      raw_data: %{"platform" => "x", "verified" => true}
    ]
  end

  defp get_mock_oauth_user_info("facebook") do
    [
      email: "user@example.com",
      provider: :facebook,
      provider_id: "fb_#{System.unique_integer([:positive])}",
      name: "Test User",
      avatar_url: "https://example.com/fb_avatar.jpg",
      raw_data: %{"platform" => "facebook", "verified" => true}
    ]
  end

  defp get_mock_oauth_user_info("google") do
    [
      email: "user@example.com",
      provider: :google,
      provider_id: "google_#{System.unique_integer([:positive])}",
      name: "Test User",
      avatar_url: "https://example.com/google_avatar.jpg",
      raw_data: %{"platform" => "google", "verified" => true}
    ]
  end

  defp get_mock_oauth_user_info("apple") do
    [
      email: "user@example.com",
      provider: :apple,
      provider_id: "apple_#{System.unique_integer([:positive])}",
      name: "Test User",
      avatar_url: "https://example.com/apple_avatar.jpg",
      raw_data: %{"platform" => "apple", "verified" => true}
    ]
  end

  defp get_error_message("access_denied"), do: "Authentication was cancelled"
  defp get_error_message("oauth_failed"), do: "Authentication failed. Please try again."
  defp get_error_message("missing_email"), do: "Email address is required for authentication"
  defp get_error_message(_), do: "An error occurred during authentication"

  defp get_readable_error_message(%Ash.Error.Invalid{errors: errors}) do
    Enum.map_join(errors, ", ", &format_error/1)
  end

  defp format_error(%{message: message}), do: message
  defp format_error(error) when is_binary(error), do: error
  defp format_error(_), do: "Invalid input"
end
