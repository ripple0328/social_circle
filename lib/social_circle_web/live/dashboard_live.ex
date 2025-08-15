defmodule SocialCircleWeb.DashboardLive do
  use SocialCircleWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    current_user_id = session["user_id"]

    if current_user_id do
      {:ok,
       socket
       |> assign(:current_user_id, current_user_id)}
    else
      {:ok, push_navigate(socket, to: ~p"/auth")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={%{id: @current_user_id}}>
      <div class="max-w-7xl mx-auto py-8 px-4">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p class="mt-2 text-gray-600">Welcome to your social media dashboard</p>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Quick Actions</h2>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <.link
              navigate={~p"/settings/accounts"}
              class="flex items-center p-4 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              <.icon name="hero-cog-6-tooth" class="h-8 w-8 text-indigo-600 mr-3" />
              <div>
                <h3 class="text-sm font-medium text-gray-900">Manage Accounts</h3>
                <p class="text-sm text-gray-500">Connect or disconnect social media accounts</p>
              </div>
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
