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
      <div class="mb-6">
        <.link
          navigate={~p"/c/#{@community.name}/#{@page.slug}"}
          class="text-sm text-base-content/60 hover:text-base-content"
        >
          &larr; {@page.title}
        </.link>
      </div>

      <h1 class="text-2xl font-bold mb-6">Pending Proposals</h1>

      <div :if={@grouped_proposals == %{}} class="text-base-content/50">
        No pending proposals.
      </div>

      <div :for={{section, proposals} <- @grouped_proposals} class="mb-8">
        <h2 class="text-lg font-semibold mb-3 text-base-content/70">
          Section: {section_title(section)}
        </h2>
        <div class="space-y-2">
          <.link
            :for={proposal <- proposals}
            navigate={~p"/c/#{@community.name}/#{@page.slug}/proposals/#{proposal.id}"}
            class="block p-4 rounded-lg border border-base-300 hover:bg-base-200/50 transition"
          >
            <div class="flex items-center justify-between">
              <div>
                <span :if={proposal.proposed_title} class="font-medium">
                  Title change: "{proposal.proposed_title}"
                </span>
                <span :if={!proposal.proposed_title} class="font-medium text-base-content/60">
                  Content edit
                </span>
              </div>
              <span class="badge badge-sm badge-warning rounded-full">pending</span>
            </div>
            <div class="text-sm text-base-content/50 mt-1">
              by {proposal.author.nickname} · {Calendar.strftime(proposal.inserted_at, "%b %d, %Y")}
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
