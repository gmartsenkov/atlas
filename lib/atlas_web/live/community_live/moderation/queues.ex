defmodule AtlasWeb.CommunityLive.Moderation.Queues do
  @moduledoc false
  use AtlasWeb, :live_view

  alias Atlas.Communities
  alias Atlas.Communities.Proposal
  import Atlas.Communities, only: [section_title: 1]
  import AtlasWeb.CommunityLive.Moderation
  import AtlasWeb.DiffRenderer
  import AtlasWeb.BlockRenderer

  @impl true
  def mount(_params, _session, socket) do
    community = socket.assigns.community

    {:ok,
     socket
     |> assign(
       page_title: "Queue - #{community.name}",
       skipped_ids: [],
       reviewed_count: 0
     )
     |> load_next_proposal()}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    proposal = socket.assigns.proposal
    reviewer = socket.assigns.current_scope.user

    case Communities.approve_proposal(proposal, reviewer) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(skipped_ids: [], reviewed_count: socket.assigns.reviewed_count + 1)
         |> put_flash(:info, "Proposal approved.")
         |> load_next_proposal()}

      {:error, :not_pending} ->
        {:noreply,
         socket
         |> put_flash(:error, "This proposal has already been reviewed.")
         |> load_next_proposal()}

      {:error, _, _, _} ->
        {:noreply, put_flash(socket, :error, "Failed to approve proposal.")}
    end
  end

  def handle_event("reject", _params, socket) do
    proposal = socket.assigns.proposal
    reviewer = socket.assigns.current_scope.user

    case Communities.reject_proposal(proposal, reviewer) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(skipped_ids: [], reviewed_count: socket.assigns.reviewed_count + 1)
         |> put_flash(:info, "Proposal rejected.")
         |> load_next_proposal()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject proposal.")}
    end
  end

  def handle_event("skip", _params, socket) do
    skipped_ids = [socket.assigns.proposal.id | socket.assigns.skipped_ids]

    {:noreply,
     socket
     |> assign(skipped_ids: skipped_ids)
     |> load_next_proposal()}
  end

  defp load_next_proposal(socket) do
    community = socket.assigns.community
    skipped_ids = socket.assigns.skipped_ids
    pending_count = Communities.count_community_pending_proposals(community)

    page = Communities.list_community_proposals(community, "pending", limit: 20)

    candidate =
      page.items
      |> Enum.reject(&(&1.id in skipped_ids))
      |> List.first()

    # If all pending were skipped, wrap around to the beginning
    {candidate, skipped_ids} =
      if is_nil(candidate) && page.items != [] do
        {List.first(page.items), []}
      else
        {candidate, skipped_ids}
      end

    proposal =
      if candidate do
        {:ok, loaded} = Communities.get_proposal(candidate.id)
        Atlas.Repo.preload(loaded, section: :page)
      end

    skipped_count = length(skipped_ids)
    current_position = socket.assigns.reviewed_count + skipped_count + 1
    total = socket.assigns.reviewed_count + pending_count

    assign(socket,
      proposal: proposal,
      pending_count: pending_count,
      skipped_ids: skipped_ids,
      current_position: current_position,
      total_in_session: total,
      empty: is_nil(proposal)
    )
  end

  defp is_page_proposal?(proposal), do: Proposal.new_page_proposal?(proposal)

  defp proposal_context(proposal) do
    if is_page_proposal?(proposal) do
      "New page: #{proposal.proposed_title}"
    else
      "#{proposal.section.page.title} > #{section_title(proposal.section)}"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mod_layout
      community={@community}
      live_action={:queue}
      is_owner={@is_owner}
      pending_count={@pending_count}
      moderated_communities={@moderated_communities}
    >
      <div class="max-w-3xl mx-auto">
        <%= if @empty do %>
          <div class="flex flex-col items-center justify-center py-16 text-base-content/40">
            <.icon name="hero-check-circle" class="size-12 mb-3" />
            <p class="text-lg font-medium">All caught up!</p>
            <p class="text-sm mt-1">No pending proposals to review.</p>
          </div>
        <% else %>
          <%!-- Sticky combined header --%>
          <div class="sticky top-2 z-10 bg-base-100 border border-base-300 rounded-xl px-4 py-2.5 mb-4 flex items-center justify-between gap-4 shadow-sm">
            <div class="min-w-0">
              <span class="font-medium text-sm truncate">{proposal_context(@proposal)}</span>
              <span class="text-xs text-base-content/50 ml-2">
                by
                <.link
                  navigate={~p"/u/#{@proposal.author.nickname}"}
                  class="hover:text-base-content transition"
                >
                  {@proposal.author.nickname}
                </.link>
                ·
                <span title={Calendar.strftime(@proposal.inserted_at, "%b %d, %Y")}>
                  {time_ago(@proposal.inserted_at)}
                </span>
              </span>
            </div>
            <div class="flex items-center gap-3 shrink-0">
              <span class="text-xs text-base-content/40">
                {@current_position} of {@total_in_session}
              </span>
              <div class="flex gap-1.5">
                <button
                  phx-click="reject"
                  onclick="document.getElementById('mod-main')?.scrollTo({top:0,behavior:'smooth'})"
                  class="btn btn-error btn-sm rounded-full"
                  data-confirm="Reject this proposal?"
                >
                  <.icon name="hero-x-mark" class="size-4" /> Reject
                </button>
                <button
                  phx-click="skip"
                  onclick="document.getElementById('mod-main')?.scrollTo({top:0,behavior:'smooth'})"
                  class="btn btn-ghost btn-sm rounded-full"
                >
                  <.icon name="hero-forward" class="size-4" /> Skip
                </button>
                <button
                  phx-click="approve"
                  onclick="document.getElementById('mod-main')?.scrollTo({top:0,behavior:'smooth'})"
                  class="btn btn-success btn-sm rounded-full"
                  data-confirm="Approve this proposal?"
                >
                  <.icon name="hero-check" class="size-4" /> Approve
                </button>
              </div>
            </div>
          </div>

          <%!-- Title change (section proposals only) --%>
          <div
            :if={
              !is_page_proposal?(@proposal) && @proposal.proposed_title &&
                @proposal.proposed_title != section_title(@proposal.section)
            }
            class="mb-4 p-4 rounded-lg border border-base-300 bg-base-200/30"
          >
            <.section_label class="mb-2">Title Change</.section_label>
            <div class="flex items-center gap-3">
              <span class="line-through text-base-content/40">
                {section_title(@proposal.section)}
              </span>
              <.icon name="hero-arrow-right" class="size-4 text-base-content/30" />
              <span class="font-semibold">{@proposal.proposed_title}</span>
            </div>
          </div>

          <%!-- Diff view --%>
          <div class="mb-6">
            <div class="p-5 rounded-lg border border-base-300 min-h-[200px] prose max-w-none">
              <%= if is_page_proposal?(@proposal) do %>
                <.render_block :for={block <- @proposal.proposed_content || []} block={block} />
                <p :if={(@proposal.proposed_content || []) == []} class="text-base-content/40 italic">
                  No content
                </p>
              <% else %>
                <.render_collapsed_diff
                  old_blocks={@proposal.section.content || []}
                  new_blocks={@proposal.proposed_content || []}
                />
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </.mod_layout>
    """
  end
end
