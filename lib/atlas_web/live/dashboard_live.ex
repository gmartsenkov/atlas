defmodule AtlasWeb.DashboardLive do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  alias Atlas.Communities.Proposal
  import Atlas.Communities, only: [section_title: 1]

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    communities = Communities.list_user_moderated_communities(user)

    selected =
      case communities do
        [first | _] -> first
        [] -> nil
      end

    {community_proposals_page, community_status_counts} =
      if selected do
        page = Communities.list_community_proposals(selected, "pending", limit: @per_page)
        counts = Communities.count_community_proposals_by_status(selected)
        {page, counts}
      else
        {%Atlas.Pagination{}, %{}}
      end

    user_proposals_page = Communities.list_user_proposals(user, "all", limit: @per_page)
    user_status_counts = Communities.count_user_proposals_by_status(user)

    {:ok,
     socket
     |> assign(
       page_title: "Dashboard",
       communities: communities,
       selected_community: selected,
       community_status_filter: "pending",
       community_proposals_page: community_proposals_page,
       community_status_counts: community_status_counts,
       user_status_filter: "all",
       user_proposals_page: user_proposals_page,
       user_status_counts: user_status_counts
     )
     |> stream(:community_proposals, community_proposals_page.items)
     |> stream(:user_proposals, user_proposals_page.items)}
  end

  @impl true
  def handle_event("select-community", %{"community_id" => id}, socket) do
    selected = Enum.find(socket.assigns.communities, &(to_string(&1.id) == id))

    if selected do
      page = Communities.list_community_proposals(selected, "pending", limit: @per_page)
      counts = Communities.count_community_proposals_by_status(selected)

      {:noreply,
       socket
       |> assign(
         selected_community: selected,
         community_status_filter: "pending",
         community_proposals_page: page,
         community_status_counts: counts
       )
       |> stream(:community_proposals, page.items, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("filter-community-proposals", %{"status" => status}, socket) do
    community = socket.assigns.selected_community
    page = Communities.list_community_proposals(community, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(community_status_filter: status, community_proposals_page: page)
     |> stream(:community_proposals, page.items, reset: true)}
  end

  def handle_event("load-more-community-proposals", _params, socket) do
    %{
      community_proposals_page: prev,
      selected_community: community,
      community_status_filter: status
    } =
      socket.assigns

    new_offset = prev.offset + prev.limit

    page =
      Communities.list_community_proposals(community, status,
        limit: @per_page,
        offset: new_offset
      )

    {:noreply,
     socket
     |> assign(community_proposals_page: page)
     |> stream(:community_proposals, page.items)}
  end

  def handle_event("filter-user-proposals", %{"status" => status}, socket) do
    user = socket.assigns.current_scope.user
    page = Communities.list_user_proposals(user, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(user_status_filter: status, user_proposals_page: page)
     |> stream(:user_proposals, page.items, reset: true)}
  end

  def handle_event("load-more-user-proposals", _params, socket) do
    %{user_proposals_page: prev, user_status_filter: status} = socket.assigns
    user = socket.assigns.current_scope.user
    new_offset = prev.offset + prev.limit
    page = Communities.list_user_proposals(user, status, limit: @per_page, offset: new_offset)

    {:noreply,
     socket
     |> assign(user_proposals_page: page)
     |> stream(:user_proposals, page.items)}
  end

  defp proposal_href(proposal, community_name) do
    if Proposal.new_page_proposal?(proposal) do
      ~p"/c/#{community_name}/page-proposals/#{proposal.id}"
    else
      page_slug = proposal.section.page.slug
      ~p"/c/#{community_name}/#{page_slug}/proposals/#{proposal.id}"
    end
  end

  defp community_name_for(proposal) do
    if Proposal.new_page_proposal?(proposal) do
      proposal.community.name
    else
      case proposal.section.page do
        %{community: %{name: name}} -> name
        page -> page.community.name
      end
    end
  end

  defp proposal_context(proposal) do
    if Proposal.new_page_proposal?(proposal) do
      "New page proposal"
    else
      "on #{proposal.section.page.title} \u203A #{section_title(proposal.section)}"
    end
  end

  defp total_count(status_counts) do
    status_counts |> Map.values() |> Enum.sum()
  end

  defp count_for(status_counts, "all"), do: total_count(status_counts)
  defp count_for(status_counts, status), do: Map.get(status_counts, status, 0)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto flex flex-col h-[calc(100vh-5rem)]">
      <div class="flex items-center gap-4 mb-4 shrink-0">
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <.community_selector
          :if={@selected_community && length(@communities) > 1}
          communities={@communities}
          selected={@selected_community}
        />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 min-h-0 flex-1">
        <.community_proposals_section
          :if={@selected_community}
          selected_community={@selected_community}
          status_filter={@community_status_filter}
          status_counts={@community_status_counts}
          proposals_page={@community_proposals_page}
          streams={@streams}
        />

        <.my_proposals_section
          status_filter={@user_status_filter}
          status_counts={@user_status_counts}
          proposals_page={@user_proposals_page}
          streams={@streams}
        />
      </div>
    </div>
    """
  end

  defp community_proposals_section(assigns) do
    ~H"""
    <section class="flex flex-col min-h-0">
      <div class="shrink-0">
        <h2 class="text-xl font-bold mb-4">Community Proposals</h2>

        <.status_tabs
          tabs={[{"Pending", "pending"}, {"Approved", "approved"}, {"Rejected", "rejected"}]}
          current={@status_filter}
          counts={@status_counts}
          event="filter-community-proposals"
        />
      </div>

      <div class="overflow-y-auto min-h-0 flex-1">
        <div :if={@proposals_page.total == 0} class="text-base-content/50 py-4">
          No proposals found.
        </div>

        <div id="community-proposals-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, proposal} <- @streams.community_proposals} id={dom_id}>
            <.proposal_card
              proposal={proposal}
              href={proposal_href(proposal, @selected_community.name)}
              context={proposal_context(proposal)}
            />
          </div>
        </div>

        <.load_more page={@proposals_page} on_load_more="load-more-community-proposals" />
      </div>
    </section>
    """
  end

  defp my_proposals_section(assigns) do
    ~H"""
    <section class="flex flex-col min-h-0">
      <div class="shrink-0">
        <h2 class="text-xl font-bold mb-4">My Proposals</h2>

        <.status_tabs
          tabs={[
            {"All", "all"},
            {"Pending", "pending"},
            {"Approved", "approved"},
            {"Rejected", "rejected"}
          ]}
          current={@status_filter}
          counts={@status_counts}
          event="filter-user-proposals"
        />
      </div>

      <div class="overflow-y-auto min-h-0 flex-1">
        <div :if={@proposals_page.total == 0} class="text-base-content/50 py-4">
          No proposals found.
        </div>

        <div id="user-proposals-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, proposal} <- @streams.user_proposals} id={dom_id}>
            <.proposal_card
              proposal={proposal}
              href={proposal_href(proposal, community_name_for(proposal))}
              context={proposal_context(proposal)}
            />
          </div>
        </div>

        <.load_more page={@proposals_page} on_load_more="load-more-user-proposals" />
      </div>
    </section>
    """
  end

  defp community_selector(assigns) do
    ~H"""
    <div class="dropdown">
      <div
        tabindex="0"
        role="button"
        class="flex items-center gap-3 px-4 py-2 rounded-xl border border-base-300 bg-base-200/50 hover:bg-base-200 transition cursor-pointer"
      >
        <.community_icon icon={@selected.icon} size={:sm} />
        <span class="font-semibold text-sm">{@selected.name}</span>
        <.icon name="hero-chevron-up-down-mini" class="size-4 text-base-content/40" />
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu border border-base-300 bg-base-100 rounded-xl z-10 w-64 p-2 shadow-lg mt-1"
      >
        <li :for={c <- @communities}>
          <button
            phx-click="select-community"
            phx-value-community_id={c.id}
            onclick="document.activeElement?.blur()"
            class={["flex items-center gap-3", c.id == @selected.id && "active"]}
          >
            <.community_icon icon={c.icon} size={:sm} />
            <span class="text-sm">{c.name}</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  defp status_tabs(assigns) do
    ~H"""
    <div class="flex gap-1 mb-6">
      <button
        :for={{label, value} <- @tabs}
        phx-click={@event}
        phx-value-status={value}
        class={[
          "px-3 py-1.5 rounded-full text-sm font-medium transition",
          if(@current == value,
            do: "bg-base-content/10 text-base-content",
            else: "text-base-content/50 hover:bg-base-content/5 hover:text-base-content"
          )
        ]}
      >
        {label}
        <span class="text-xs ml-1 opacity-60">
          ({count_for(@counts, value)})
        </span>
      </button>
    </div>
    """
  end
end
