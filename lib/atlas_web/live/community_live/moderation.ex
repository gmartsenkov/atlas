defmodule AtlasWeb.CommunityLive.Moderation do
  @moduledoc false
  use AtlasWeb, :html

  alias Atlas.{Authorization, Communities}

  def on_mount(:ensure_moderator, %{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        user = socket.assigns.current_scope.user
        is_moderator = Communities.moderator?(user, community)
        is_owner = Authorization.community_owner?(user, community)

        if Authorization.can_moderate_community?(user, community, is_moderator) do
          pending_count = Communities.count_community_pending_proposals(community)

          {:cont,
           Phoenix.Component.assign(socket,
             full_bleed: true,
             community: community,
             is_owner: is_owner,
             is_moderator: is_moderator,
             pending_count: pending_count
           )}
        else
          {:halt,
           socket
           |> Phoenix.LiveView.put_flash(
             :error,
             "You don't have permission to moderate this community."
           )
           |> Phoenix.LiveView.push_navigate(to: ~p"/c/#{name}")}
        end
    end
  end

  attr :community, :map, required: true
  attr :live_action, :atom, required: true
  attr :is_owner, :boolean, required: true
  attr :pending_count, :integer, required: true

  def mod_sidebar(assigns) do
    ~H"""
    <aside class="w-64 border-r border-base-300 bg-base-200/30 flex flex-col shrink-0">
      <div class="p-4 border-b border-base-300">
        <.link navigate={~p"/c/#{@community.name}"} class="flex items-center gap-3 group">
          <.community_icon icon={@community.icon} size={:sm} />
          <div class="min-w-0">
            <h2 class="font-bold text-sm truncate group-hover:text-primary transition">
              {@community.name}
            </h2>
            <span class="text-xs text-base-content/40">Moderation</span>
          </div>
        </.link>
      </div>
      <nav class="flex-1 p-2 space-y-1">
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/queues"}
          icon="hero-queue-list"
          label="Queues"
          active={@live_action == :queues}
          badge={@pending_count}
        />
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/members"}
          icon="hero-users"
          label="Mods & Members"
          active={@live_action == :members}
        />
        <.mod_nav_link
          :if={@is_owner}
          href={~p"/mod/#{@community.name}/settings"}
          icon="hero-cog-6-tooth"
          label="General Settings"
          active={@live_action == :settings}
        />
      </nav>
    </aside>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :badge, :integer, default: nil

  def mod_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition",
        if(@active,
          do: "bg-base-content/10 text-base-content",
          else: "text-base-content/60 hover:bg-base-content/5 hover:text-base-content"
        )
      ]}
    >
      <.icon name={@icon} class="size-4" />
      <span class="flex-1">{@label}</span>
      <span
        :if={@badge && @badge > 0}
        class="badge badge-sm badge-primary rounded-full"
      >
        {@badge}
      </span>
    </.link>
    """
  end

  def mod_layout(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)]">
      <.mod_sidebar
        community={@community}
        live_action={@live_action}
        is_owner={@is_owner}
        pending_count={@pending_count}
      />
      <main class="flex-1 overflow-y-auto p-6">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end
end
