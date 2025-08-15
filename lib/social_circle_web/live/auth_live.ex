defmodule SocialCircleWeb.AuthLive do
  use SocialCircleWeb, :live_view

  alias SocialCircleWeb.Layouts

  @impl true
  def mount(params, session, socket) do
    current_user_id = session["user_id"]
    
    # Redirect authenticated users to dashboard
    if current_user_id do
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    else
      error = params["error"]
      error_message = get_error_message(error)
      
      {:ok,
       socket
       |> assign(:error_message, error_message)
       |> assign(:loading_provider, nil)}
    end
  end

  @impl true
  def handle_event("auth_provider", %{"provider" => provider}, socket) do
    case provider do
      provider when provider in ["x", "facebook", "google", "apple"] ->
        # Show loading state first, then redirect after a brief moment
        send(self(), {:redirect_to_oauth, provider})
        {:noreply, assign(socket, :loading_provider, provider)}
      
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid authentication provider")
         |> assign(:loading_provider, nil)}
    end
  end

  @impl true
  def handle_info({:redirect_to_oauth, provider}, socket) do
    oauth_path = case provider do
      "x" -> ~p"/auth/x"
      "facebook" -> ~p"/auth/facebook"
      "google" -> ~p"/auth/google"
      "apple" -> ~p"/auth/apple"
      _ -> ~p"/auth"
    end
    
    {:noreply, push_navigate(socket, to: oauth_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="auth-container min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center px-4">
      <div class="w-full max-w-md space-y-8">
        <!-- Header -->
        <div class="text-center">
          <div class="mx-auto h-12 w-12 flex items-center justify-center rounded-full bg-indigo-600">
            <.icon name="hero-user-group" class="h-6 w-6 text-white" />
          </div>
          <h1 class="mt-6 text-3xl font-bold tracking-tight text-gray-900">
            Unify Your Social Media Experience
          </h1>
          <p class="mt-2 text-sm text-gray-600">
            Connect your accounts to get started
          </p>
        </div>

        <!-- Error Message -->
        <div :if={@error_message} class="rounded-md bg-red-50 p-4" role="alert">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name="hero-x-circle" class="h-5 w-5 text-red-400" />
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-red-800">{@error_message}</p>
            </div>
          </div>
        </div>

        <!-- Authentication Options -->
        <div class="space-y-4">
          <!-- Primary X Authentication -->
          <button
            type="button"
            phx-click="auth_provider"
            phx-value-provider="x"
            disabled={@loading_provider == "x"}
            class="auth-button-primary group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-black hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
          >
            <span :if={@loading_provider == "x"} class="absolute left-0 inset-y-0 flex items-center pl-3">
              <div class="animate-spin h-5 w-5 border-2 border-white border-t-transparent rounded-full"></div>
            </span>
            <span :if={@loading_provider != "x"} class="absolute left-0 inset-y-0 flex items-center pl-3">
              <svg class="h-5 w-5 fill-current" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
              </svg>
            </span>
            <span :if={@loading_provider == "x"}>Connecting...</span>
            <span :if={@loading_provider != "x"}>Continue with X</span>
          </button>

          <!-- Secondary Authentication Options -->
          <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
            <!-- Facebook -->
            <button
              type="button"
              phx-click="auth_provider"
              phx-value-provider="facebook"
              disabled={@loading_provider == "facebook"}
              class="auth-button-secondary relative flex justify-center py-2.5 px-3 border border-gray-300 text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              <span :if={@loading_provider == "facebook"} class="spinner animate-spin h-4 w-4 border-2 border-blue-600 border-t-transparent rounded-full"></span>
              <span :if={@loading_provider != "facebook"} class="text-blue-600">
                <.icon name="hero-user-group" class="h-4 w-4" />
              </span>
              <span :if={@loading_provider == "facebook"} class="ml-2 text-xs">Connecting</span>
              <span :if={@loading_provider != "facebook"} class="ml-2 text-xs">Continue with Facebook</span>
            </button>

            <!-- Google -->
            <button
              type="button"
              phx-click="auth_provider"
              phx-value-provider="google"
              disabled={@loading_provider == "google"}
              class="auth-button-secondary relative flex justify-center py-2.5 px-3 border border-gray-300 text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              <span :if={@loading_provider == "google"} class="spinner animate-spin h-4 w-4 border-2 border-red-500 border-t-transparent rounded-full"></span>
              <span :if={@loading_provider != "google"} class="text-red-500">
                <.icon name="hero-globe-alt" class="h-4 w-4" />
              </span>
              <span :if={@loading_provider == "google"} class="ml-2 text-xs">Connecting</span>
              <span :if={@loading_provider != "google"} class="ml-2 text-xs">Continue with Google</span>
            </button>

            <!-- Apple -->
            <button
              type="button"
              phx-click="auth_provider"
              phx-value-provider="apple"
              disabled={@loading_provider == "apple"}
              class="auth-button-secondary relative flex justify-center py-2.5 px-3 border border-gray-300 text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
            >
              <span :if={@loading_provider == "apple"} class="spinner animate-spin h-4 w-4 border-2 border-gray-800 border-t-transparent rounded-full"></span>
              <span :if={@loading_provider != "apple"} class="text-gray-800">
                <.icon name="hero-device-phone-mobile" class="h-4 w-4" />
              </span>
              <span :if={@loading_provider == "apple"} class="ml-2 text-xs">Connecting</span>
              <span :if={@loading_provider != "apple"} class="ml-2 text-xs">Continue with Apple</span>
            </button>
          </div>
        </div>

        <!-- Trust Indicators -->
        <div class="mt-8">
          <div class="grid grid-cols-3 gap-4 text-center">
            <div class="flex flex-col items-center">
              <.icon name="hero-shield-check" class="h-6 w-6 text-green-500" />
              <span class="mt-1 text-xs text-gray-600">Secure</span>
            </div>
            <div class="flex flex-col items-center">
              <.icon name="hero-eye-slash" class="h-6 w-6 text-blue-500" />
              <span class="mt-1 text-xs text-gray-600">Private</span>
            </div>
            <div class="flex flex-col items-center">
              <.icon name="hero-key" class="h-6 w-6 text-purple-500" />
              <span class="mt-1 text-xs text-gray-600">No Passwords</span>
            </div>
          </div>
        </div>

        <!-- Terms and Privacy -->
        <div class="text-center text-xs text-gray-500 space-x-4">
          <a href="/terms" class="hover:text-gray-700 underline">Terms of Service</a>
          <a href="/privacy" class="hover:text-gray-700 underline">Privacy Policy</a>
        </div>
      </div>
    </div>

    <Layouts.flash_group flash={@flash} />
    """
  end

  # Private helper functions

  defp get_error_message("access_denied"), do: "Authentication was cancelled"
  defp get_error_message("oauth_failed"), do: "Authentication failed. Please try again."
  defp get_error_message("missing_email"), do: "Email address is required for authentication"
  defp get_error_message(_), do: nil
end