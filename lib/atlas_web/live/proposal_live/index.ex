defmodule AtlasWeb.ProposalLive.Index do
  use AtlasWeb, :live_view

  alias Atlas.{Authorization, Communities}
  import Atlas.Communities, only: [section_title: 1]

  @per_page 20

  @impl true
  def mount(
        %{"community_name" => community_name, "page_slug" => page_slug},
        _session,
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    with {:ok, community} <- Communities.get_community_by_name(community_name),
         {:ok, page} <- Communities.get_page_by_slugs(community_name, page_slug),
         true <- Authorization.can_view_proposals?(current_user, page) do
      proposals_page = Communities.list_pending_proposals(page, limit: @per_page)

      {:ok,
       socket
       |> assign(
         page_title: "Proposals — #{page.title}",
         community: community,
         page: page,
         proposals_page: proposals_page
       )
       |> stream(:proposals, proposals_page.items)}
    else
      {:error, :not_found} -> raise AtlasWeb.NotFoundError
      false -> raise AtlasWeb.NotFoundError
    end
  end

  @impl true
  def handle_event("load-more", _params, socket) do
    %{proposals_page: prev, page: page} = socket.assigns
    new_offset = prev.offset + prev.limit

    proposals_page =
      Communities.list_pending_proposals(page, limit: @per_page, offset: new_offset)

    {:noreply,
     socket
     |> assign(proposals_page: proposals_page)
     |> stream(:proposals, proposals_page.items)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-8">
      <.back_link navigate={~p"/c/#{@community.name}/#{@page.slug}"}>{@page.title}</.back_link>

      <h1 class="text-2xl font-bold mb-6">Pending Proposals</h1>

      <div :if={@proposals_page.total == 0} class="text-base-content/50">
        No pending proposals.
      </div>

      <div id="proposals-list" phx-update="stream" class="space-y-2">
        <div :for={{dom_id, proposal} <- @streams.proposals} id={dom_id}>
          <.proposal_card
            proposal={proposal}
            href={~p"/c/#{@community.name}/#{@page.slug}/proposals/#{proposal.id}"}
            context={"Section: #{section_title(proposal.section)}"}
          />
        </div>
      </div>

      <.load_more page={@proposals_page} on_load_more="load-more" />
    </div>
    """
  end
end
