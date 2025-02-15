defmodule PlaygroundWeb.Router do
  use PlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PlaygroundWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlaygroundWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/new", HomeLive, :new
    live "/join", HomeLive, :join
    live "/join/:code", HomeLive, :join

    live "/games", ListGamesLive, :list
    live "/games/:game", ListGamesLive, :show

    live "/rooms/:code", RoomLive, :index

    post "/new_room", RoomController, :new
    post "/join_room", RoomController, :join
    post "/quit_room", RoomController, :quit
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlaygroundWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:playground, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PlaygroundWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
