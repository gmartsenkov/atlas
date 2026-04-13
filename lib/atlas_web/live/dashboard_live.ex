defmodule AtlasWeb.DashboardLive do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  alias Atlas.Communities.Proposal

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    proposals_page = Communities.list_user_proposals(user, "all", limit: @per_page)
    status_counts = Communities.count_user_proposals_by_status(user)

    {:ok,
     socket
     |> assign(
       page_title: "My Proposals",
       status_filter: "all",
       proposals_page: proposals_page,
       status_counts: status_counts
     )
     |> stream(:proposals, proposals_page.items)}
  end

  @impl true
  def handle_event("filter-proposals", %{"status" => status}, socket) do
    user = socket.assigns.current_scope.user
    page = Communities.list_user_proposals(user, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(status_filter: status, proposals_page: page)
     |> stream(:proposals, page.items, reset: true)}
  end

  def handle_event("load-more", _params, socket) do
    %{proposals_page: prev, status_filter: status} = socket.assigns
    user = socket.assigns.current_scope.user
    new_offset = prev.offset + prev.limit
    page = Communities.list_user_proposals(user, status, limit: @per_page, offset: new_offset)

    {:noreply,
     socket
     |> assign(proposals_page: page)
     |> stream(:proposals, page.items)}
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
      "on #{proposal.section.page.title}"
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
    <div class="max-w-4xl mx-auto">
      <h1 class="text-2xl font-bold mb-4">My Proposals</h1>

      <.status_tabs
        tabs={[
          {"All", "all"},
          {"Pending", "pending"},
          {"Approved", "approved"},
          {"Rejected", "rejected"}
        ]}
        current={@status_filter}
        counts={@status_counts}
        event="filter-proposals"
      />

      <div class="h-[calc(100vh-16rem)]">
        <div class="overflow-y-auto min-h-0 h-full">
          <div :if={@proposals_page.total == 0} class="text-base-content/50 py-4">
            No proposals found.
          </div>

          <div id="proposals-list" phx-update="stream" class="space-y-2">
            <div :for={{dom_id, proposal} <- @streams.proposals} id={dom_id}>
              <.proposal_card
                proposal={proposal}
                href={proposal_href(proposal, community_name_for(proposal))}
                context={proposal_context(proposal)}
              />
            </div>
          </div>

          <.load_more page={@proposals_page} on_load_more="load-more" />
        </div>
      </div>
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
