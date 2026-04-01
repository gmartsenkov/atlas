defmodule AtlasWeb.Router do
  use AtlasWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AtlasWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AtlasWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/communities", CommunitiesLive.Index
    live "/communities/new", CommunityLive.Form, :new
    live "/c/:community_slug", CommunityLive.Show
    live "/c/:community_slug/new", PageLive.Form, :new
    live "/c/:community_slug/:page_slug", CommunityLive.Show
    live "/c/:community_slug/:page_slug/edit", PageLive.Edit
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:atlas, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AtlasWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
