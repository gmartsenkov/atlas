defmodule AtlasWeb.ProposalLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  import AtlasWeb.BlockRenderer
  import Atlas.Communities, only: [section_title: 1]

  @impl true
  def mount(
        %{"community_name" => community_name, "page_slug" => page_slug, "id" => id},
        _session,
        socket
      ) do
    with {:ok, community} <- Communities.get_community_by_name(community_name),
         {:ok, page} <- Communities.get_page_by_slugs(community_name, page_slug),
         {:ok, proposal} <- Communities.get_proposal(id) do
      current_user = socket.assigns.current_scope.user
      is_page_owner = page.owner_id == current_user.id

      {:ok,
       assign(socket,
         page_title: "Proposal — #{page.title}",
         community: community,
         page: page,
         proposal: proposal,
         is_page_owner: is_page_owner,
         is_page_proposal: false,
         comment_text: "",
         view_mode: "side-by-side"
       )}
    else
      {:error, :not_found} ->
        {:ok, redirect(socket, to: ~p"/404")}
    end
  end

  def mount(
        %{"community_name" => community_name, "id" => id},
        _session,
        socket
      ) do
    with {:ok, community} <- Communities.get_community_by_name(community_name),
         {:ok, proposal} <- Communities.get_proposal(id) do
      current_user = socket.assigns.current_scope.user
      is_owner = community.owner_id == current_user.id

      {:ok,
       assign(socket,
         page_title: "Page Proposal — #{proposal.proposed_title}",
         community: community,
         page: nil,
         proposal: proposal,
         is_page_owner: is_owner,
         is_page_proposal: true,
         comment_text: "",
         view_mode: "proposed"
       )}
    else
      {:error, :not_found} ->
        {:ok, redirect(socket, to: ~p"/404")}
    end
  end

  @impl true
  def handle_event("approve", _params, socket) do
    if !socket.assigns.is_page_owner do
      {:noreply, put_flash(socket, :error, "Only the page owner can approve proposals.")}
    else
      reviewer = socket.assigns.current_scope.user

      case Communities.approve_proposal(socket.assigns.proposal, reviewer) do
        {:ok, %{page: page}} when not is_nil(page) ->
          {:noreply,
           socket
           |> put_flash(:info, "Proposal approved! New page created.")
           |> push_navigate(to: ~p"/c/#{socket.assigns.community.name}/#{page.slug}")}

        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Proposal approved! Section content updated.")
           |> push_navigate(
             to: ~p"/c/#{socket.assigns.community.name}/#{socket.assigns.page.slug}/proposals"
           )}

        {:error, _, _, _} ->
          {:noreply, put_flash(socket, :error, "Failed to approve proposal")}
      end
    end
  end

  def handle_event("reject", _params, socket) do
    if !socket.assigns.is_page_owner do
      {:noreply, put_flash(socket, :error, "Only the page owner can reject proposals.")}
    else
      reviewer = socket.assigns.current_scope.user

      case Communities.reject_proposal(socket.assigns.proposal, reviewer) do
        {:ok, _} ->
          redirect_path =
            if socket.assigns.is_page_proposal do
              ~p"/c/#{socket.assigns.community.name}/about"
            else
              ~p"/c/#{socket.assigns.community.name}/#{socket.assigns.page.slug}/proposals"
            end

          {:noreply,
           socket
           |> put_flash(:info, "Proposal rejected.")
           |> push_navigate(to: redirect_path)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to reject proposal")}
      end
    end
  end

  def handle_event("toggle-view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, view_mode: mode)}
  end

  def handle_event("update-comment", %{"value" => text}, socket) do
    {:noreply, assign(socket, comment_text: text)}
  end

  def handle_event("add-comment", %{"comment" => body}, socket) do
    user = socket.assigns.current_scope.user
    proposal = socket.assigns.proposal

    with {:ok, _comment} <- Communities.add_proposal_comment(proposal, user, %{body: body}),
         {:ok, proposal} <- Communities.get_proposal(proposal.id) do
      {:noreply, assign(socket, proposal: proposal, comment_text: "")}
    else
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add comment")}
    end
  end

  defp back_path(assigns) do
    if assigns.is_page_proposal do
      ~p"/c/#{assigns.community.name}/about"
    else
      ~p"/c/#{assigns.community.name}/#{assigns.page.slug}/proposals"
    end
  end

  defp subtitle(assigns) do
    if assigns.is_page_proposal do
      "New page: #{assigns.proposal.proposed_title} (#{assigns.proposal.proposed_slug})"
    else
      "Section: #{section_title(assigns.proposal.section)}"
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
        {if @is_page_proposal, do: "Community", else: "All Proposals"}
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
            · {Calendar.strftime(@proposal.inserted_at, "%b %d, %Y")}
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
        </div>
      </div>

      <%!-- Content display --%>
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
      <% else %>
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
      <div :if={@is_page_owner && @proposal.status == "pending"} class="flex gap-3 mb-8">
        <button
          phx-click="approve"
          class="btn btn-success btn-sm rounded-full"
          data-confirm={approve_confirm(assigns)}
        >
          <.icon name="hero-check" class="size-4" /> Approve
        </button>
        <button
          phx-click="reject"
          class="btn btn-error btn-sm rounded-full"
          data-confirm="Reject this proposal?"
        >
          <.icon name="hero-x-mark" class="size-4" /> Reject
        </button>
      </div>

      <%!-- Comments --%>
      <div class="border-t border-base-300 pt-6">
        <h3 class="text-lg font-semibold mb-4">Comments</h3>

        <div :if={@proposal.comments == []} class="text-base-content/50 mb-4">
          No comments yet.
        </div>

        <div class="space-y-3 mb-6">
          <div :for={comment <- @proposal.comments} class="p-3 rounded-lg bg-base-200/50">
            <.user_attribution
              nickname={comment.author.nickname}
              date={comment.inserted_at}
              format="%b %d, %Y %H:%M"
            />
            <p class="text-sm">{comment.body}</p>
          </div>
        </div>

        <form phx-submit="add-comment" class="flex gap-2">
          <input
            type="text"
            name="comment"
            value={@comment_text}
            phx-keyup="update-comment"
            placeholder="Add a comment..."
            class="input input-bordered input-sm flex-1 rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
          <button
            type="submit"
            disabled={@comment_text == ""}
            class="btn btn-primary btn-sm rounded-full"
          >
            Comment
          </button>
        </form>
      </div>
    </div>
    """
  end
end
