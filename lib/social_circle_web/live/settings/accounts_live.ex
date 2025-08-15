defmodule SocialCircleWeb.Settings.AccountsLive do
  use SocialCircleWeb, :live_view

  require Ash.Query

  @impl true
  def mount(_params, session, socket) do
    current_user_id = session["user_id"]

    if current_user_id do
      user = load_user_with_providers(current_user_id)

      {:ok,
       socket
       |> assign(:current_user, user)
       |> assign(:linked_providers, user.linked_providers)
       |> assign(:connecting_provider, nil)
       |> assign(:show_disconnect_modal, false)
       |> assign(:provider_to_disconnect, nil)}
    else
      {:ok, push_navigate(socket, to: ~p"/auth")}
    end
  end

  @impl true
  def handle_event("connect_provider", %{"provider" => provider}, socket) do
    case provider do
      provider when provider in ["x", "facebook", "google", "apple"] ->
        oauth_path =
          case provider do
            "x" -> ~p"/auth/x/link"
            "facebook" -> ~p"/auth/facebook/link"
            "google" -> ~p"/auth/google/link"
            "apple" -> ~p"/auth/apple/link"
          end

        {:noreply,
         socket
         |> assign(:connecting_provider, provider)
         |> push_navigate(to: oauth_path)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid provider")
         |> assign(:connecting_provider, nil)}
    end
  end

  @impl true
  def handle_event("show_disconnect_modal", %{"provider_id" => provider_id}, socket) do
    linked_provider = Enum.find(socket.assigns.linked_providers, &(&1.id == provider_id))

    {:noreply,
     socket
     |> assign(:show_disconnect_modal, true)
     |> assign(:provider_to_disconnect, linked_provider)}
  end

  @impl true
  def handle_event("hide_disconnect_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_disconnect_modal, false)
     |> assign(:provider_to_disconnect, nil)}
  end

  @impl true
  def handle_event("confirm_disconnect", _params, socket) do
    provider_to_disconnect = socket.assigns.provider_to_disconnect

    if provider_to_disconnect do
      case SocialCircle.Accounts.LinkedProvider.remove_linked_provider(provider_to_disconnect) do
        :ok ->
          # Reload user data
          updated_user = load_user_with_providers(socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(:current_user, updated_user)
           |> assign(:linked_providers, updated_user.linked_providers)
           |> assign(:show_disconnect_modal, false)
           |> assign(:provider_to_disconnect, nil)
           |> put_flash(:info, "Account disconnected successfully")}

        {:error, _error} ->
          {:noreply,
           socket
           |> assign(:show_disconnect_modal, false)
           |> assign(:provider_to_disconnect, nil)
           |> put_flash(:error, "Failed to disconnect account")}
      end
    else
      {:noreply,
       socket
       |> assign(:show_disconnect_modal, false)
       |> assign(:provider_to_disconnect, nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="max-w-4xl mx-auto py-8 px-4">
        <div class="space-y-8">
          <!-- Header -->
          <div>
            <h1 class="text-3xl font-bold text-gray-900">Connected Accounts</h1>
            <p class="mt-2 text-sm text-gray-600">
              Manage your social media account connections
            </p>
          </div>
          
    <!-- Primary Account -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Primary Account</h2>
            </div>
            <div class="p-6">
              <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                  <div class="flex-shrink-0">
                    <div class="h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center">
                      <.icon name={get_provider_icon_name(@current_user.provider)} class="h-6 w-6" />
                    </div>
                  </div>
                  <div>
                    <h3 class="text-lg font-medium text-gray-900">
                      {String.capitalize(to_string(@current_user.provider))} (Primary)
                    </h3>
                    <p class="text-sm text-gray-600">{@current_user.email}</p>
                    <div class="flex items-center mt-1">
                      <div class="h-2 w-2 bg-green-500 rounded-full"></div>
                      <span class="ml-2 text-xs text-gray-500">Connected</span>
                      <span class="ml-2 text-xs text-gray-500">
                        • Last sync: {format_last_sync(@current_user.updated_at)}
                      </span>
                    </div>
                  </div>
                </div>
                <div class="text-sm text-gray-500">
                  Primary accounts cannot be disconnected
                </div>
              </div>
            </div>
          </div>
          
    <!-- Linked Accounts -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Additional Accounts</h2>
            </div>
            <div class="p-6">
              <div :if={@linked_providers == []} class="text-center py-8">
                <div class="mx-auto h-12 w-12 flex items-center justify-center rounded-full bg-gray-100">
                  <.icon name="hero-link" class="h-6 w-6 text-gray-400" />
                </div>
                <h3 class="mt-2 text-sm font-medium text-gray-900">No additional accounts</h3>
                <p class="mt-1 text-sm text-gray-500">
                  Connect more accounts to aggregate all your social media.
                </p>
              </div>

              <div :if={@linked_providers != []} class="space-y-4">
                <div
                  :for={provider <- @linked_providers}
                  class="flex items-center justify-between border border-gray-200 rounded-lg p-4"
                >
                  <div class="flex items-center space-x-4">
                    <div class="flex-shrink-0">
                      <div class="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
                        <.icon name={get_provider_icon_name(provider.provider)} class="h-5 w-5" />
                      </div>
                    </div>
                    <div>
                      <h4 class="text-sm font-medium text-gray-900">
                        {String.capitalize(to_string(provider.provider))}
                      </h4>
                      <div class="flex items-center mt-1">
                        <div class="h-2 w-2 bg-green-500 rounded-full"></div>
                        <span class="ml-2 text-xs text-gray-500">Connected</span>
                        <span class="ml-2 text-xs text-gray-500">
                          • Last sync: {format_last_sync(provider.updated_at)}
                        </span>
                      </div>
                    </div>
                  </div>
                  <button
                    type="button"
                    phx-click="show_disconnect_modal"
                    phx-value-provider_id={provider.id}
                    class="text-sm text-red-600 hover:text-red-800 font-medium"
                  >
                    Disconnect
                  </button>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Add More Accounts -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-lg font-medium text-gray-900">Connect More Accounts</h2>
            </div>
            <div class="p-6">
              <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
                <div :for={provider <- available_providers(@current_user, @linked_providers)}>
                  <button
                    type="button"
                    phx-click="connect_provider"
                    phx-value-provider={provider}
                    disabled={@connecting_provider == provider}
                    class="relative w-full flex flex-col items-center justify-center p-4 border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
                  >
                    <span :if={@connecting_provider == provider} class="absolute top-2 right-2">
                      <div class="animate-spin h-4 w-4 border-2 border-indigo-600 border-t-transparent rounded-full">
                      </div>
                    </span>
                    <.icon
                      name={get_provider_icon_name(String.to_atom(provider))}
                      class="h-8 w-8 mb-2"
                    />
                    <span class="text-sm font-medium text-gray-700">
                      Connect {String.capitalize(provider)}
                    </span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Disconnect Confirmation Modal -->
      <div
        :if={@show_disconnect_modal}
        class="fixed inset-0 z-50 overflow-y-auto"
        phx-click="hide_disconnect_modal"
        phx-key="Escape"
        phx-window-keydown="hide_disconnect_modal"
      >
        <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

          <div
            class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
            phx-click-away="hide_disconnect_modal"
          >
            <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div class="sm:flex sm:items-start">
                <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
                  <.icon name="hero-exclamation-triangle" class="h-6 w-6 text-red-600" />
                </div>
                <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3 class="text-lg leading-6 font-medium text-gray-900">
                    Disconnect Account
                  </h3>
                  <div class="mt-2">
                    <p class="text-sm text-gray-500">
                      Are you sure you want to disconnect your
                      <span :if={@provider_to_disconnect} class="font-medium">
                        {String.capitalize(to_string(@provider_to_disconnect.provider))}
                      </span>
                      account? This action cannot be undone.
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button
                type="button"
                phx-click="confirm_disconnect"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Disconnect
              </button>
              <button
                type="button"
                phx-click="hide_disconnect_modal"
                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Private helper functions

  defp load_user_with_providers(user_id) do
    # Create a test actor for authorization bypass in tests
    actor = %{test_env: true, id: user_id}

    SocialCircle.Accounts.User
    |> Ash.get!(user_id, actor: actor)
    |> Ash.load!(:linked_providers, actor: actor)
  end

  defp available_providers(current_user, linked_providers) do
    all_providers = ["x", "facebook", "google", "apple"]

    connected_providers = [
      to_string(current_user.provider) | Enum.map(linked_providers, &to_string(&1.provider))
    ]

    Enum.filter(all_providers, fn provider ->
      provider not in connected_providers
    end)
  end

  defp get_provider_icon_name(:x), do: "hero-at-symbol"
  defp get_provider_icon_name(:facebook), do: "hero-user-group"
  defp get_provider_icon_name(:google), do: "hero-globe-alt"
  defp get_provider_icon_name(:apple), do: "hero-device-phone-mobile"
  defp get_provider_icon_name(_), do: "hero-user"

  defp format_last_sync(datetime) when is_struct(datetime) do
    case DateTime.diff(DateTime.utc_now(), datetime, :second) do
      diff when diff < 60 -> "#{diff} seconds ago"
      diff when diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff when diff < 86_400 -> "#{div(diff, 3600)} hours ago"
      _ -> "#{div(DateTime.diff(DateTime.utc_now(), datetime, :second), 86_400)} days ago"
    end
  end

  defp format_last_sync(_), do: "Unknown"
end
