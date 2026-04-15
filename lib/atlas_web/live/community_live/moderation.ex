defmodule AtlasWeb.CommunityLive.Moderation do
  @moduledoc false
  use AtlasWeb, :html

  alias Atlas.Authorization
  alias Atlas.Communities.{CommunityManager, Proposals, ReportsContext}

  def on_mount(:ensure_moderator, %{"community_name" => name}, _session, socket) do
    case CommunityManager.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        user = socket.assigns.current_scope.user
        is_moderator = CommunityManager.moderator?(user, community)
        is_owner = Authorization.community_owner?(user, community)

        if Authorization.can_moderate_community?(user, community, is_moderator) do
          pending_count = Proposals.count_community_pending_proposals(community)

          report_status_counts = ReportsContext.count_community_reports_by_status(community)
          pending_reports_count = Map.get(report_status_counts, "pending", 0)

          {:cont,
           Phoenix.Component.assign(socket,
             full_bleed: true,
             community: community,
             is_owner: is_owner,
             is_moderator: is_moderator,
             pending_count: pending_count,
             pending_reports_count: pending_reports_count
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
  attr :pending_reports_count, :integer, required: true
  attr :moderated_communities, :list, default: []

  def mod_sidebar(assigns) do
    other_communities =
      Enum.reject(assigns.moderated_communities, &(&1.id == assigns.community.id))

    assigns = Phoenix.Component.assign(assigns, :other_communities, other_communities)

    ~H"""
    <aside class="hidden lg:flex w-64 h-full border-r border-base-300 bg-base-200/30 flex-col shrink-0">
      <div class="p-4 border-b border-base-300 flex items-center gap-2">
        <.link
          navigate={~p"/c/#{@community.name}"}
          class="p-1.5 rounded-lg text-base-content/40 hover:text-base-content hover:bg-base-content/5 transition shrink-0"
        >
          <.icon name="hero-arrow-left" class="size-5" />
        </.link>
        <div class={["dropdown flex-1 min-w-0", @other_communities != [] && "dropdown-bottom"]}>
          <div
            tabindex="0"
            role="button"
            class="flex items-center gap-3 group cursor-pointer w-full"
          >
            <.community_icon icon={@community.icon} size={:sm} />
            <div class="min-w-0 flex-1">
              <h2 class="font-bold text-sm truncate group-hover:text-primary transition">
                {@community.name}
              </h2>
              <span class="text-xs text-base-content/40">Moderation</span>
            </div>
            <.icon
              :if={@other_communities != []}
              name="hero-chevron-up-down-mini"
              class="size-4 text-base-content/40 shrink-0"
            />
          </div>
          <ul
            :if={@other_communities != []}
            tabindex="0"
            class="dropdown-content menu border border-base-300 bg-base-100 rounded-xl z-10 w-56 p-2 shadow-lg mt-1"
          >
            <li :for={c <- @other_communities}>
              <.link
                navigate={~p"/mod/#{c.name}"}
                onclick="document.activeElement?.blur()"
                class="flex items-center gap-3"
              >
                <.community_icon icon={c.icon} size={:sm} />
                <span class="text-sm truncate">{c.name}</span>
              </.link>
            </li>
          </ul>
        </div>
      </div>
      <nav class="flex-1 p-2 space-y-1">
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/queue"}
          icon="hero-bolt"
          label="Queue"
          active={@live_action == :queue}
          badge={@pending_count}
        />
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/proposals"}
          icon="hero-queue-list"
          label="Proposals"
          active={@live_action == :proposals}
        />
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/reports"}
          icon="hero-flag"
          label="Reports"
          active={@live_action == :reports}
          badge={@pending_reports_count}
        />
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/members"}
          icon="hero-users"
          label="Mods & Members"
          active={@live_action == :members}
        />
        <.mod_nav_link
          href={~p"/mod/#{@community.name}/restricted"}
          icon="hero-no-symbol"
          label="Restricted Users"
          active={@live_action == :restricted}
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

  attr :community, :map, required: true
  attr :live_action, :atom, required: true
  attr :is_owner, :boolean, required: true
  attr :pending_count, :integer, required: true
  attr :pending_reports_count, :integer, required: true
  attr :moderated_communities, :list, default: []
  slot :inner_block, required: true

  def mod_layout(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)]">
      <.mod_sidebar
        community={@community}
        live_action={@live_action}
        is_owner={@is_owner}
        pending_count={@pending_count}
        pending_reports_count={@pending_reports_count}
        moderated_communities={@moderated_communities}
      />
      <main id="mod-main" class="flex-1 overflow-y-auto p-6">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end
end
