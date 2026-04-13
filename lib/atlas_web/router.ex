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
      live "/dashboard", DashboardLive
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/communities/new", CommunityLive.Form, :new
      live "/c/:community_name/collections", CommunityLive.Collections
      live "/c/:community_name/new", PageLive.Form, :new
      live "/c/:community_name/propose-page", PageLive.ProposeNew
      live "/c/:community_name/page-proposals/:id/edit", ProposalLive.Edit, :edit_page_proposal
      live "/c/:community_name/page-proposals/:id", ProposalLive.Show, :page_proposal
      live "/c/:community_name/:page_slug/edit", PageLive.Edit
      live "/c/:community_name/:page_slug/sections/:section_id/propose", PageLive.Propose
      live "/c/:community_name/:page_slug/proposals/:id/edit", ProposalLive.Edit, :edit
      live "/c/:community_name/:page_slug/proposals/:id", ProposalLive.Show
    end

    live_session :community_moderation,
      on_mount: [
        {AtlasWeb.UserAuth, :require_authenticated},
        {AtlasWeb.CommunityLive.Moderation, :ensure_moderator}
      ] do
      live "/mod/:community_name", CommunityLive.Moderation.Queues, :queue
      live "/mod/:community_name/queue", CommunityLive.Moderation.Queues, :queue
      live "/mod/:community_name/proposals", CommunityLive.Moderation.Proposals, :proposals
      live "/mod/:community_name/members", CommunityLive.Moderation.TeamMembers, :members
      live "/mod/:community_name/settings", CommunityLive.Moderation.General, :settings
    end

    post "/users/update-password", UserSessionController, :update_password
    post "/api/uploads/presign", UploadController, :presign
  end

  scope "/", AtlasWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{AtlasWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/", HomeLive
      live "/terms", LegalLive.Terms
      live "/privacy", LegalLive.Privacy
      live "/contact", LegalLive.Contact
      live "/faq", LegalLive.FAQ
      live "/communities", CommunitiesLive.Index
      live "/u/:nickname", UserLive.Profile
      live "/c/:community_name", CommunityLive.Show
      live "/c/:community_name/about", CommunityLive.About
      live "/c/:community_name/:page_slug", CommunityLive.Show
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
