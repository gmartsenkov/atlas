defmodule AtlasWeb.CommunityLive.Moderation.Proposals do
  @moduledoc false
  use AtlasWeb, :live_view

  alias Atlas.Communities
  alias Atlas.Communities.Proposal
  import Atlas.Communities, only: [section_title: 1]
  import AtlasWeb.CommunityLive.Moderation

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    community = socket.assigns.community
    status_counts = Communities.count_community_proposals_by_status(community)
    page = Communities.list_community_proposals(community, "pending", limit: @per_page)

    {:ok,
     socket
     |> assign(
       page_title: "Proposals - #{community.name}",
       proposal_status_filter: "pending",
       proposal_status_counts: status_counts,
       proposals_page: page
     )
     |> stream(:proposals, page.items)}
  end

  @impl true
  def handle_event("filter-proposals", %{"status" => status}, socket) do
    community = socket.assigns.community
    page = Communities.list_community_proposals(community, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(proposal_status_filter: status, proposals_page: page)
     |> stream(:proposals, page.items, reset: true)}
  end

  def handle_event("load-more-proposals", _params, socket) do
    %{proposals_page: prev, community: community, proposal_status_filter: status} =
      socket.assigns

    new_offset = prev.offset + prev.limit

    page =
      Communities.list_community_proposals(community, status,
        limit: @per_page,
        offset: new_offset
      )

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

  defp proposal_context(proposal) do
    if Proposal.new_page_proposal?(proposal) do
      "New page proposal"
    else
      "on #{proposal.section.page.title} > #{section_title(proposal.section)}"
    end
  end

  defp count_for(status_counts, "all") do
    status_counts |> Map.values() |> Enum.sum()
  end

  defp count_for(status_counts, status), do: Map.get(status_counts, status, 0)

  @impl true
  def render(assigns) do
    ~H"""
    <.mod_layout
      community={@community}
      live_action={:proposals}
      is_owner={@is_owner}
      pending_count={@pending_count}
      pending_reports_count={@pending_reports_count}
      moderated_communities={@moderated_communities}
    >
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-bold mb-4">Proposals</h1>

        <.status_tabs
          tabs={[{"Pending", "pending"}, {"Approved", "approved"}, {"Rejected", "rejected"}]}
          current={@proposal_status_filter}
          counts={@proposal_status_counts}
          event="filter-proposals"
        />

        <div :if={@proposals_page.total == 0} class="text-base-content/50 py-8 text-center">
          No proposals found.
        </div>

        <div id="mod-proposals-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, proposal} <- @streams.proposals} id={dom_id}>
            <.proposal_card
              proposal={proposal}
              href={proposal_href(proposal, @community.name)}
              context={proposal_context(proposal)}
            />
          </div>
        </div>

        <.load_more page={@proposals_page} on_load_more="load-more-proposals" />
      </div>
    </.mod_layout>
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
