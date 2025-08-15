defmodule SocialCircleWeb.Router do
  use SocialCircleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SocialCircleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/", SocialCircleWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/auth", AuthLive
    live "/dashboard", DashboardLive
  end

  # Settings routes
  scope "/settings", SocialCircleWeb.Settings do
    pipe_through :browser

    live "/accounts", AccountsLive
  end

  # Authentication routes
  scope "/auth", SocialCircleWeb do
    pipe_through :browser

    # OAuth provider redirects
    get "/:provider", AuthController, :provider
    
    # OAuth callbacks
    get "/:provider/callback", AuthController, :callback
    
    # Account linking (for authenticated users)
    get "/:provider/link", AuthController, :provider
    get "/:provider/link/callback", AuthController, :link_callback
    
    # Session management
    delete "/logout", AuthController, :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", SocialCircleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:social_circle, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SocialCircleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
