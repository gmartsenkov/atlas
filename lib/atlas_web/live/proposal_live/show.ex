defmodule AtlasWeb.ProposalLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Authorization
  alias Atlas.Communities.{CommunityManager, PagesContext, Proposals}
  alias Atlas.Communities.Proposal.{Approve, Reject}
  import AtlasWeb.BlockRenderer
  import AtlasWeb.DiffRenderer
  import Atlas.Communities.Sections, only: [section_title: 1]

  @impl true
  def mount(
        %{"community_name" => community_name, "page_slug" => page_slug, "id" => id},
        _session,
        socket
      ) do
    with {:ok, community} <- CommunityManager.get_community_by_name(community_name),
         {:ok, page} <- PagesContext.get_page_by_slugs(community_name, page_slug),
         {:ok, proposal} <- Proposals.get_proposal(id),
         true <- proposal.section != nil and proposal.section.page_id == page.id do
      current_user = socket.assigns.current_scope.user
      is_moderator = CommunityManager.moderator?(current_user, community)

      {:ok,
       assign(socket,
         page_title: "Proposal — #{page.title}",
         community: community,
         page: page,
         proposal: proposal,
         is_page_owner:
           Authorization.can_review_proposal?(current_user, community, page, is_moderator),
         can_edit:
           Authorization.can_edit_proposal?(current_user, proposal, community, is_moderator),
         is_page_proposal: false,
         view_mode: "diff"
       )}
    else
      {:error, :not_found} -> raise AtlasWeb.NotFoundError
      false -> raise AtlasWeb.NotFoundError
    end
  end

  def mount(
        %{"community_name" => community_name, "id" => id},
        _session,
        socket
      ) do
    with {:ok, community} <- CommunityManager.get_community_by_name(community_name),
         {:ok, proposal} <- Proposals.get_proposal(id),
         true <- proposal.community_id == community.id do
      current_user = socket.assigns.current_scope.user
      is_moderator = CommunityManager.moderator?(current_user, community)

      {:ok,
       assign(socket,
         page_title: "Page Proposal — #{proposal.proposed_title}",
         community: community,
         page: nil,
         proposal: proposal,
         is_page_owner:
           Authorization.can_review_proposal?(current_user, community, nil, is_moderator),
         can_edit:
           Authorization.can_edit_proposal?(current_user, proposal, community, is_moderator),
         is_page_proposal: true,
         view_mode: "proposed"
       )}
    else
      {:error, :not_found} -> raise AtlasWeb.NotFoundError
      false -> raise AtlasWeb.NotFoundError
    end
  end

  @impl true
  def handle_event("approve", _params, socket) do
    cond do
      !socket.assigns.is_page_owner ->
        {:noreply, put_flash(socket, :error, "Only the page owner can approve proposals.")}

      socket.assigns.proposal.status != "pending" ->
        {:noreply, put_flash(socket, :error, "This proposal has already been reviewed.")}

      true ->
        do_approve(socket)
    end
  end

  def handle_event("reject", _params, socket) do
    cond do
      !socket.assigns.is_page_owner ->
        {:noreply, put_flash(socket, :error, "Only the page owner can reject proposals.")}

      socket.assigns.proposal.status != "pending" ->
        {:noreply, put_flash(socket, :error, "This proposal has already been reviewed.")}

      true ->
        do_reject(socket)
    end
  end

  def handle_event("toggle-view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, view_mode: mode)}
  end

  defp do_approve(socket) do
    reviewer = socket.assigns.current_scope.user
    community = socket.assigns.community
    page = socket.assigns.page
    is_moderator = CommunityManager.moderator?(reviewer, community)

    case Approve.call(socket.assigns.proposal, reviewer, community, page, is_moderator) do
      {:ok, %{page: page}} when not is_nil(page) ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal approved! New page created.")
         |> push_navigate(to: ~p"/c/#{socket.assigns.community.name}/#{page.slug}")}

      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal approved! Section content updated.")
         |> push_navigate(to: ~p"/mod/#{socket.assigns.community.name}/proposals")}

      {:error, :not_pending} ->
        {:noreply, put_flash(socket, :error, "This proposal has already been reviewed.")}

      {:error, :proposal, :not_pending, _} ->
        {:noreply, put_flash(socket, :error, "This proposal has already been reviewed.")}

      {:error, _, _, _} ->
        {:noreply, put_flash(socket, :error, "Failed to approve proposal")}
    end
  end

  defp do_reject(socket) do
    reviewer = socket.assigns.current_scope.user
    community = socket.assigns.community
    page = socket.assigns.page
    is_moderator = CommunityManager.moderator?(reviewer, community)

    case Reject.call(socket.assigns.proposal, reviewer, community, page, is_moderator) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Proposal rejected.")
         |> push_navigate(to: ~p"/mod/#{socket.assigns.community.name}/proposals")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject proposal")}
    end
  end

  defp back_path(%{community: community}) do
    ~p"/mod/#{community.name}/proposals"
  end

  defp subtitle(assigns) do
    if assigns.is_page_proposal do
      "New page: #{assigns.proposal.proposed_title} (#{assigns.proposal.proposed_slug})"
    else
      "Section: #{section_title(assigns.proposal.section)}"
    end
  end

  defp edit_path(assigns) do
    if assigns.is_page_proposal do
      ~p"/c/#{assigns.community.name}/page-proposals/#{assigns.proposal.id}/edit"
    else
      ~p"/c/#{assigns.community.name}/#{assigns.page.slug}/proposals/#{assigns.proposal.id}/edit"
    end
  end

  defp approve_confirm(assigns) do
    if assigns.is_page_proposal do
      "Approve this proposal? This will create a new page."
    else
      "Approve this proposal? Section content will be updated."
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-8">
      <.back_link navigate={back_path(assigns)}>
        Back
      </.back_link>

      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold">Proposal Review</h1>
          <p class="text-base-content/50 mt-1">
            {subtitle(assigns)} · by
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
          </p>
        </div>
        <.status_badge status={@proposal.status} />
      </div>

      <%!-- Title change (section proposals only) --%>
      <div
        :if={
          !@is_page_proposal && @proposal.proposed_title &&
            @proposal.proposed_title != section_title(@proposal.section)
        }
        class="mb-6 p-4 rounded-lg border border-base-300 bg-base-200/30"
      >
        <.section_label class="mb-2">Title Change</.section_label>
        <div class="flex items-center gap-3">
          <span class="line-through text-base-content/40">{section_title(@proposal.section)}</span>
          <.icon name="hero-arrow-right" class="size-4 text-base-content/30" />
          <span class="font-semibold">{@proposal.proposed_title}</span>
        </div>
      </div>

      <%!-- Content toggle --%>
      <div class="mb-4">
        <div class="flex gap-1 bg-base-200 rounded-lg p-1 w-fit">
          <button
            phx-click="toggle-view"
            phx-value-mode="proposed"
            class={[
              "px-3 py-1.5 text-sm rounded-md transition",
              if(@view_mode == "proposed",
                do: "bg-base-100 font-medium shadow-sm",
                else: "text-base-content/60 hover:text-base-content"
              )
            ]}
          >
            Proposed
          </button>
          <button
            :if={!@is_page_proposal}
            phx-click="toggle-view"
            phx-value-mode="current"
            class={[
              "px-3 py-1.5 text-sm rounded-md transition",
              if(@view_mode == "current",
                do: "bg-base-100 font-medium shadow-sm",
                else: "text-base-content/60 hover:text-base-content"
              )
            ]}
          >
            Current
          </button>
          <button
            :if={!@is_page_proposal}
            phx-click="toggle-view"
            phx-value-mode="side-by-side"
            class={[
              "px-3 py-1.5 text-sm rounded-md transition",
              if(@view_mode == "side-by-side",
                do: "bg-base-100 font-medium shadow-sm",
                else: "text-base-content/60 hover:text-base-content"
              )
            ]}
          >
            Side by Side
          </button>
          <button
            :if={!@is_page_proposal}
            phx-click="toggle-view"
            phx-value-mode="diff"
            class={[
              "px-3 py-1.5 text-sm rounded-md transition",
              if(@view_mode == "diff",
                do: "bg-base-100 font-medium shadow-sm",
                else: "text-base-content/60 hover:text-base-content"
              )
            ]}
          >
            Diff
          </button>
        </div>
      </div>

      <%!-- Content display --%>
      <%= if @view_mode == "diff" && !@is_page_proposal do %>
        <div class="mb-8">
          <div class="p-5 rounded-lg border border-base-300 min-h-[200px] prose max-w-none">
            <.render_diff
              old_blocks={@proposal.section.content || []}
              new_blocks={@proposal.proposed_content || []}
            />
          </div>
        </div>
      <% end %>
      <%= if @view_mode == "side-by-side" && !@is_page_proposal do %>
        <div class="grid grid-cols-2 gap-4 mb-8">
          <div>
            <.section_label class="mb-2">Current</.section_label>
            <div class="p-5 rounded-lg border border-base-300 bg-base-200/30 min-h-[200px] prose prose-sm max-w-none">
              <.render_block :for={block <- @proposal.section.content || []} block={block} />
              <p :if={(@proposal.section.content || []) == []} class="text-base-content/40 italic">
                No content
              </p>
            </div>
          </div>
          <div>
            <.section_label class="mb-2">Proposed</.section_label>
            <div class="p-5 rounded-lg border border-primary/30 bg-primary/5 min-h-[200px] prose prose-sm max-w-none">
              <.render_block :for={block <- @proposal.proposed_content || []} block={block} />
              <p :if={(@proposal.proposed_content || []) == []} class="text-base-content/40 italic">
                No content changes
              </p>
            </div>
          </div>
        </div>
      <% end %>
      <%= if @view_mode in ["proposed", "current"] || @is_page_proposal do %>
        <div class="mb-8">
          <div class={[
            "p-5 rounded-lg border min-h-[200px] prose max-w-none",
            if(@view_mode == "proposed" || @is_page_proposal,
              do: "border-primary/30 bg-primary/5",
              else: "border-base-300 bg-base-200/30"
            )
          ]}>
            <%= if @view_mode == "proposed" || @is_page_proposal do %>
              <.render_block :for={block <- @proposal.proposed_content || []} block={block} />
              <p :if={(@proposal.proposed_content || []) == []} class="text-base-content/40 italic">
                No content changes
              </p>
            <% else %>
              <.render_block :for={block <- @proposal.section.content || []} block={block} />
              <p :if={(@proposal.section.content || []) == []} class="text-base-content/40 italic">
                No content
              </p>
            <% end %>
          </div>
        </div>
      <% end %>

      <%!-- Actions --%>
      <div
        :if={@proposal.status == "pending" && (@is_page_owner || @can_edit)}
        class="flex gap-3 mb-8"
      >
        <.link
          :if={@can_edit}
          navigate={edit_path(assigns)}
          class="btn btn-ghost btn-sm rounded-full"
        >
          <.icon name="hero-pencil-square" class="size-4" /> Edit
        </.link>
        <button
          :if={@is_page_owner}
          phx-click="approve"
          class="btn btn-success btn-sm rounded-full"
          data-confirm={approve_confirm(assigns)}
        >
          <.icon name="hero-check" class="size-4" /> Approve
        </button>
        <button
          :if={@is_page_owner}
          phx-click="reject"
          class="btn btn-error btn-sm rounded-full"
          data-confirm="Reject this proposal?"
        >
          <.icon name="hero-x-mark" class="size-4" /> Reject
        </button>
      </div>

      <.live_component
        module={AtlasWeb.CommentsSection}
        id="proposal-comments"
        commentable={@proposal}
        current_user={@current_scope.user}
        is_owner={@is_page_owner}
        is_moderator={false}
        member_roles={%{}}
      />
    </div>
    """
  end
end
