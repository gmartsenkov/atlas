defmodule AtlasWeb.ProposalLive.Index do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  import Atlas.Communities, only: [section_title: 1]

  @impl true
  def mount(
        %{"community_name" => community_name, "page_slug" => page_slug},
        _session,
        socket
      ) do
    community = Communities.get_community_by_name!(community_name)
    page = Communities.get_page_by_slugs!(community_name, page_slug)
    proposals = Communities.list_pending_proposals(page)

    # Group proposals by section
    grouped =
      Enum.group_by(proposals, fn p -> p.section end, fn p -> p end)

    {:ok,
     assign(socket,
       page_title: "Proposals — #{page.title}",
       community: community,
       page: page,
       grouped_proposals: grouped
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-8">
      <.back_link navigate={~p"/c/#{@community.name}/#{@page.slug}"}>{@page.title}</.back_link>

      <h1 class="text-2xl font-bold mb-6">Pending Proposals</h1>

      <div :if={@grouped_proposals == %{}} class="text-base-content/50">
        No pending proposals.
      </div>

      <div :for={{section, proposals} <- @grouped_proposals} class="mb-8">
        <h2 class="text-lg font-semibold mb-3 text-base-content/70">
          Section: {section_title(section)}
        </h2>
        <div class="space-y-2">
          <.proposal_card
            :for={proposal <- proposals}
            proposal={proposal}
            href={~p"/c/#{@community.name}/#{@page.slug}/proposals/#{proposal.id}"}
          />
        </div>
      </div>
    </div>
    """
  end
end
