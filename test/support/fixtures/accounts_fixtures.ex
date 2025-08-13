defmodule SocialCircle.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SocialCircle.Accounts` context using Ash Framework.
  """

  alias SocialCircle.Accounts.User

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      provider: :x,
      provider_id: "x#{System.unique_integer()}",
      name: "Test User #{System.unique_integer()}",
      avatar_url: "https://example.com/avatar#{System.unique_integer()}.jpg"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> then(fn user_attrs ->
        User
        |> Ash.Changeset.for_create(:create_from_oauth, user_attrs)
        |> Ash.create()
      end)

    user
  end

  def x_user_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:provider, :x)
    |> Map.put(:provider_id, "x#{System.unique_integer()}")
    |> user_fixture()
  end

  def facebook_user_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:provider, :facebook)
    |> Map.put(:provider_id, "fb#{System.unique_integer()}")
    |> user_fixture()
  end

  def google_user_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:provider, :google)
    |> Map.put(:provider_id, "google#{System.unique_integer()}")
    |> user_fixture()
  end

  def apple_user_fixture(attrs \\ %{}) do
    attrs
    |> Map.put(:provider, :apple)
    |> Map.put(:provider_id, "apple#{System.unique_integer()}")
    |> Map.put(:avatar_url, nil)  # Apple doesn't provide avatars
    |> user_fixture()
  end

  def user_with_linked_providers_fixture(primary_provider \\ :x, linked_providers \\ [:google, :facebook]) do
    # Create user with primary provider
    user = user_fixture(%{provider: primary_provider})

    # Link additional providers
    Enum.reduce(linked_providers, user, fn provider, acc_user ->
      link_attrs = %{
        provider: provider,
        provider_id: "#{provider}#{System.unique_integer()}"
      }

      {:ok, updated_user} =
        acc_user
        |> Ash.Changeset.for_update(:link_provider, link_attrs)
        |> Ash.update()

      updated_user
    end)
  end

  def oauth_response_fixture(provider \\ :x, attrs \\ %{}) do
    base_response = case provider do
      :x ->
        %{
          "provider" => "x",
          "uid" => "x#{System.unique_integer()}",
          "info" => %{
            "email" => unique_user_email(),
            "name" => "X User #{System.unique_integer()}",
            "nickname" => "xuser#{System.unique_integer()}",
            "image" => "https://pbs.twimg.com/profile_images/#{System.unique_integer()}/avatar.jpg"
          },
          "extra" => %{
            "raw_info" => %{
              "user" => %{
                "id" => "x#{System.unique_integer()}",
                "username" => "xuser#{System.unique_integer()}",
                "verified" => false,
                "followers_count" => Enum.random(100..10000)
              }
            }
          }
        }

      :facebook ->
        %{
          "provider" => "facebook",
          "uid" => "fb#{System.unique_integer()}",
          "info" => %{
            "email" => unique_user_email(),
            "name" => "Facebook User #{System.unique_integer()}",
            "image" => "https://graph.facebook.com/#{System.unique_integer()}/picture"
          },
          "extra" => %{
            "raw_info" => %{
              "id" => "fb#{System.unique_integer()}",
              "name" => "Facebook User",
              "verified" => false
            }
          }
        }

      :google ->
        %{
          "provider" => "google",
          "uid" => "google#{System.unique_integer()}",
          "info" => %{
            "email" => unique_user_email(),
            "name" => "Google User #{System.unique_integer()}",
            "image" => "https://lh3.googleusercontent.com/a/avatar#{System.unique_integer()}"
          },
          "extra" => %{
            "raw_info" => %{
              "sub" => "google#{System.unique_integer()}",
              "name" => "Google User",
              "email_verified" => true
            }
          }
        }

      :apple ->
        %{
          "provider" => "apple",
          "uid" => "apple#{System.unique_integer()}.privaterelay",
          "info" => %{
            "email" => "privaterelay#{System.unique_integer()}@privaterelay.appleid.com",
            "name" => "Apple User #{System.unique_integer()}"
          },
          "extra" => %{
            "raw_info" => %{
              "sub" => "apple#{System.unique_integer()}.privaterelay",
              "email_verified" => true,
              "is_private_email" => true,
              "real_user_status" => 1
            }
          }
        }
    end

    deep_merge(base_response, attrs)
  end

  def oauth_error_fixture(provider \\ :x, error_type \\ "access_denied") do
    %{
      "provider" => to_string(provider),
      "strategy" => provider_strategy(provider),
      "error" => error_type,
      "error_description" => error_description(error_type)
    }
  end

  # Helper function to log in a user in tests
  def log_in_user(conn, user) do
    token = Phoenix.Token.sign(SocialCircleWeb.Endpoint, "user auth", user.id)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_id, user.id)
    |> Plug.Conn.put_session(:user_token, token)
  end

  # Helper function to extract user from conn in tests
  def extract_user_id(conn) do
    Plug.Conn.get_session(conn, :user_id)
  end

  # Private helpers
  defp provider_strategy(:x), do: "twitter"
  defp provider_strategy(:facebook), do: "facebook"
  defp provider_strategy(:google), do: "google"
  defp provider_strategy(:apple), do: "apple"

  defp error_description("access_denied"), do: "The user denied the request"
  defp error_description("invalid_request"), do: "The request is missing a required parameter"
  defp error_description("server_error"), do: "The authorization server encountered an unexpected condition"
  defp error_description(_), do: "An unknown error occurred"

  defp deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, %{} = left, %{} = right) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end
end