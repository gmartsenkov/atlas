defmodule AtlasWeb.CommunityLive.About do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  alias Atlas.Communities.Proposal
  import Atlas.Communities, only: [section_title: 1]

  @per_page 20

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        status_counts = Communities.count_community_proposals_by_status(community)

        {:ok,
         socket
         |> assign(
           page_title: "About — #{community.name}",
           community: community,
           page_count: length(community.pages),
           status_counts: status_counts,
           status_filter: "all",
           proposals_page: %Atlas.Pagination{}
         )
         |> stream(:proposals, [])}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    status = params["status"] || "all"

    page =
      Communities.list_community_proposals(socket.assigns.community, status, limit: @per_page)

    {:noreply,
     socket
     |> assign(status_filter: status, proposals_page: page)
     |> stream(:proposals, page.items, reset: true)}
  end

  @impl true
  def handle_event("load-more-proposals", _params, socket) do
    %{proposals_page: prev, community: community, status_filter: status} = socket.assigns
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

  defp total_proposals(status_counts) do
    status_counts |> Map.values() |> Enum.sum()
  end

  defp proposal_href(community, proposal) do
    if Proposal.new_page_proposal?(proposal) do
      ~p"/c/#{community.name}/page-proposals/#{proposal.id}"
    else
      ~p"/c/#{community.name}/#{proposal.section.page.slug}/proposals/#{proposal.id}"
    end
  end

  defp proposal_context(proposal) do
    if Proposal.new_page_proposal?(proposal) do
      "New page proposal"
    else
      "on #{proposal.section.page.title} › #{section_title(proposal.section)}"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-8">
      <.back_link navigate={~p"/c/#{@community.name}"}>{@community.name}</.back_link>

      <%!-- Community Info Card --%>
      <div class="border border-base-300 rounded-xl p-6 mb-8 bg-base-200/30">
        <div class="flex items-start gap-4 mb-4">
          <.community_icon icon={@community.icon} size={:lg} />
          <div>
            <h1 class="text-2xl font-bold">{@community.name}</h1>
            <p :if={@community.description} class="text-base-content/60 mt-1">
              {@community.description}
            </p>
          </div>
        </div>

        <div class="text-sm text-base-content/50 mb-4">
          Created by
          <.link
            navigate={~p"/u/#{@community.owner.nickname}"}
            class="text-base-content/70 font-medium hover:text-base-content transition"
          >
            {@community.owner.nickname}
          </.link>
          · {Calendar.strftime(@community.inserted_at, "%b %d, %Y")}
        </div>

        <div class="flex gap-4 text-sm text-base-content/60">
          <span class="font-medium">{@page_count} pages</span>
          <span class="text-base-content/20">·</span>
          <span class="font-medium">{total_proposals(@status_counts)} proposals</span>
        </div>
      </div>

      <%!-- Proposals Section --%>
      <h2 class="text-xl font-bold mb-4">Proposals</h2>

      <%!-- Filter tabs --%>
      <div class="flex gap-1 mb-6">
        <.link
          :for={
            {label, value} <- [
              {"All", "all"},
              {"Pending", "pending"},
              {"Approved", "approved"},
              {"Rejected", "rejected"}
            ]
          }
          patch={
            if value == "all",
              do: ~p"/c/#{@community.name}/about",
              else: ~p"/c/#{@community.name}/about?status=#{value}"
          }
          class={[
            "px-3 py-1.5 rounded-full text-sm font-medium transition",
            if(@status_filter == value,
              do: "bg-base-content/10 text-base-content",
              else: "text-base-content/50 hover:bg-base-content/5 hover:text-base-content"
            )
          ]}
        >
          {label}
          <span class="text-xs ml-1 opacity-60">
            ({if value == "all",
              do: total_proposals(@status_counts),
              else: Map.get(@status_counts, value, 0)})
          </span>
        </.link>
      </div>

      <%!-- Proposal list --%>
      <div :if={@proposals_page.total == 0} class="text-base-content/50 py-4">
        No proposals found.
      </div>

      <div id="proposals-list" phx-update="stream" class="space-y-2">
        <div :for={{dom_id, proposal} <- @streams.proposals} id={dom_id}>
          <.proposal_card
            proposal={proposal}
            href={proposal_href(@community, proposal)}
            context={proposal_context(proposal)}
          />
        </div>
      </div>

      <.load_more page={@proposals_page} on_load_more="load-more-proposals" />
    </div>
    """
  end
end
