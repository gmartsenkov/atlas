defmodule AtlasWeb.Router do
  use AtlasWeb, :router

  import AtlasWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AtlasWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
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

  ## Authentication routes

  scope "/", AtlasWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{AtlasWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/communities/new", CommunityLive.Form, :new
      live "/c/:community_name/edit", CommunityLive.Edit
      live "/c/:community_name/new", PageLive.Form, :new
      live "/c/:community_name/:page_slug/edit", PageLive.Edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", AtlasWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{AtlasWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/", HomeLive
      live "/communities", CommunitiesLive.Index
      live "/c/:community_name", CommunityLive.Show
      live "/c/:community_name/:page_slug", CommunityLive.Show
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
