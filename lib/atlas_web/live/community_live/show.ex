defmodule AtlasWeb.CommunityLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.{Authorization, Communities}
  import AtlasWeb.BlockRenderer

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        current_user = current_user(socket)

        is_member =
          if current_user, do: Communities.member?(current_user, community), else: false

        is_owner = Authorization.community_owner?(current_user, community)

        suggestions_enabled = community.suggestions_enabled

        pending_proposal_count =
          if suggestions_enabled,
            do: Communities.count_community_pending_proposals(community),
            else: 0

        {collected_pages, uncollected_pages} =
          group_pages_by_collection(community.pages, community.collections)

        {:ok,
         assign(socket,
           full_bleed: true,
           community: community,
           pages: community.pages,
           collected_pages: collected_pages,
           uncollected_pages: uncollected_pages,
           is_member: is_member,
           is_owner: is_owner,
           suggestions_enabled: suggestions_enabled,
           pending_proposal_count: pending_proposal_count,
           auto_expand_collection_id: nil,
           search_query: "",
           sidebar_open: false
         )}
    end
  end

  defp current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: %{id: _} = user}} -> user
      _ -> nil
    end
  end

  defp group_pages_by_collection(pages, collections) do
    collected =
      collections
      |> Enum.map(fn collection ->
        collection_pages =
          pages
          |> Enum.filter(&(&1.collection_id == collection.id))
          |> Enum.sort_by(&{&1.sort_order, &1.title})

        {collection, collection_pages}
      end)
      |> Enum.filter(fn {_collection, pages} -> pages != [] end)

    uncollected =
      pages
      |> Enum.filter(&is_nil(&1.collection_id))
      |> Enum.sort_by(&{&1.sort_order, &1.title})

    {collected, uncollected}
  end

  defp assign_page(socket, page, params) do
    pending_count =
      if socket.assigns.is_owner && socket.assigns.suggestions_enabled,
        do: Communities.count_pending_proposals(page),
        else: 0

    is_page_owner = Authorization.page_owner?(current_user(socket), page)

    current_user = current_user(socket)

    is_starred =
      if current_user,
        do: Communities.page_starred?(current_user, page),
        else: false

    star_count = Communities.count_page_stars(page)

    comments = Communities.list_page_comments(page)
    comment_count = count_comments(comments)

    socket =
      socket
      |> assign(
        page_title: "#{page.title} — #{socket.assigns.community.name}",
        current_page: page,
        sections: page.sections,
        headings: Communities.extract_headings(page.sections),
        pending_count: pending_count,
        is_page_owner: is_page_owner,
        is_starred: is_starred,
        star_count: star_count,
        sidebar_open: false,
        comments: comments,
        comment_count: comment_count
      )

    case params["scroll_to"] do
      nil -> push_event(socket, "scroll-top", %{})
      id -> push_event(socket, "scroll-to", %{id: id})
    end
  end

  @impl true
  def handle_params(%{"page_slug" => page_slug} = params, _uri, socket) do
    case Communities.get_page_by_slugs(socket.assigns.community.name, page_slug) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, page} ->
        {:noreply,
         socket
         |> assign(auto_expand_collection_id: page.collection_id)
         |> assign_page(page, params)}
    end
  end

  def handle_params(_params, _uri, socket) do
    case socket.assigns.pages do
      [first | _] ->
        {:noreply,
         push_patch(socket,
           to: ~p"/c/#{socket.assigns.community.name}/#{first.slug}",
           replace: true
         )}

      [] ->
        {:noreply,
         assign(socket,
           page_title: socket.assigns.community.name,
           current_page: nil,
           sections: [],
           headings: [],
           pending_count: 0,
           is_page_owner: false,
           is_starred: false,
           star_count: 0,
           comments: [],
           comment_count: 0
         )}
    end
  end

  defp require_user(socket, fun) do
    case current_user(socket) do
      nil -> {:noreply, socket}
      user -> fun.(user)
    end
  end

  defp refresh_comments(socket) do
    page = socket.assigns.current_page
    comments = Communities.list_page_comments(page)
    assign(socket, comments: comments, comment_count: count_comments(comments))
  end

  defp count_comments(comments) do
    Enum.reduce(comments, 0, fn c, acc -> acc + 1 + length(c.replies) end)
  end

  @impl true
  def handle_event("join", _params, socket) do
    require_user(socket, fn user ->
      community = socket.assigns.community

      case Communities.join_community(user, community) do
        {:ok, _} -> {:noreply, assign(socket, is_member: true)}
        {:error, _} -> {:noreply, socket}
      end
    end)
  end

  def handle_event("leave", _params, socket) do
    require_user(socket, fn user ->
      community = socket.assigns.community

      case Communities.leave_community(user, community) do
        :ok ->
          {:noreply, assign(socket, is_member: false)}

        {:error, :owner_cannot_leave} ->
          {:noreply, put_flash(socket, :error, "Community owners cannot leave their community.")}

        {:error, :not_a_member} ->
          {:noreply, socket}
      end
    end)
  end

  def handle_event("star", _params, socket) do
    require_user(socket, fn user ->
      page = socket.assigns.current_page

      case Communities.star_page(user, page) do
        {:ok, _} ->
          {:noreply,
           assign(socket, is_starred: true, star_count: Communities.count_page_stars(page))}

        {:error, _} ->
          {:noreply, socket}
      end
    end)
  end

  def handle_event("unstar", _params, socket) do
    require_user(socket, fn user ->
      page = socket.assigns.current_page
      Communities.unstar_page(user, page)

      {:noreply,
       assign(socket, is_starred: false, star_count: Communities.count_page_stars(page))}
    end)
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  def handle_event("scroll-to-comments", _params, socket) do
    {:noreply, push_event(socket, "scroll-to", %{id: "comments"})}
  end

  @impl true
  def handle_info({:sidebar, :search_changed, query}, socket) do
    {:noreply, assign(socket, search_query: query)}
  end

  def handle_info({:comments_section, :add_comment, %{body: body}}, socket) do
    user = current_user(socket)
    page = socket.assigns.current_page

    if user do
      case Communities.add_page_comment(page, user, %{body: body}) do
        {:ok, _comment} ->
          {:noreply, refresh_comments(socket)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not post comment.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({:comments_section, :add_reply, %{parent_id: parent_id, body: body}}, socket) do
    user = current_user(socket)
    page = socket.assigns.current_page

    with true <- user != nil,
         {:ok, parent} <- Communities.get_page_comment(parent_id),
         true <- parent.page_id == page.id,
         {:ok, _reply} <- Communities.reply_to_page_comment(page, parent, user, %{body: body}) do
      {:noreply, refresh_comments(socket)}
    else
      false -> {:noreply, socket}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not post reply.")}
    end
  end

  def handle_info({:comments_section, :delete_comment, %{comment_id: id}}, socket) do
    user = current_user(socket)
    page = socket.assigns.current_page

    with {:ok, comment} <- Communities.get_page_comment(id),
         true <- comment.page_id == page.id,
         true <- Authorization.can_delete_comment?(user, comment, page) do
      Communities.delete_page_comment(comment)

      {:noreply, refresh_comments(socket)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Community topbar --%>
    <div class="sticky top-0 z-10 border-b border-base-300 bg-base-200/30 backdrop-blur-sm px-4 sm:px-6">
      <div class="flex items-center justify-between h-14">
        <div class="flex items-center gap-3 min-w-0">
          <button
            phx-click="toggle_sidebar"
            class="text-base-content/40 hover:text-base-content transition shrink-0 lg:hidden"
          >
            <.icon name="hero-bars-3" class="size-5" />
          </button>
          <.community_icon icon={@community.icon} size={:sm} />
          <h2 class="font-bold text-base truncate">{@community.name}</h2>
          <span :if={@community.owner} class="text-xs text-base-content/40 shrink-0 hidden sm:inline">
            by
            <.link
              navigate={~p"/u/#{@community.owner.nickname}"}
              class="hover:text-base-content transition"
            >
              {@community.owner.nickname}
            </.link>
          </span>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <.link
            navigate={~p"/c/#{@community.name}/about"}
            class="btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-information-circle" class="size-3.5" /> About
            <span
              :if={@suggestions_enabled && @pending_proposal_count > 0}
              class="badge badge-sm badge-primary rounded-full"
            >
              {@pending_proposal_count}
            </span>
          </.link>
          <.link
            :if={@current_scope && @current_scope.user && @is_owner}
            navigate={~p"/c/#{@community.name}/collections"}
            class="btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-folder-plus" class="size-3.5" /> Collections
          </.link>
          <.link
            :if={@current_scope && @current_scope.user && @is_owner}
            navigate={~p"/c/#{@community.name}/edit"}
            class="btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-pencil-square" class="size-3.5" /> Edit
          </.link>
          <button
            :if={@current_scope && @current_scope.user && !@is_member}
            phx-click="join"
            class="btn btn-primary btn-xs rounded-full"
          >
            <.icon name="hero-user-plus" class="size-3.5" /> Join
          </button>
          <button
            :if={@current_scope && @current_scope.user && @is_member && !@is_owner}
            phx-click="leave"
            class="btn btn-outline btn-error btn-xs rounded-full"
          >
            <.icon name="hero-arrow-right-start-on-rectangle" class="size-3.5" /> Leave
          </button>
        </div>
      </div>
    </div>

    <div class="flex h-[calc(100vh-4rem-3.5rem)] relative overflow-hidden">
      <%!-- Mobile sidebar backdrop --%>
      <div
        phx-click="toggle_sidebar"
        class={["absolute inset-0 bg-black/30 z-20 lg:hidden", !@sidebar_open && "hidden"]}
      />
      <%!-- Sidebar --%>
      <.live_component
        module={AtlasWeb.CommunitySidebar}
        id="sidebar"
        community={@community}
        collected_pages={@collected_pages}
        uncollected_pages={@uncollected_pages}
        current_page={@current_page}
        headings={@headings}
        is_owner={@is_owner}
        suggestions_enabled={@suggestions_enabled}
        current_scope={@current_scope}
        sidebar_open={@sidebar_open}
        auto_expand_collection_id={@auto_expand_collection_id}
      />

      <%!-- Main content --%>
      <main id="page-content" phx-hook="ScrollToTarget" class="flex-1 overflow-y-auto">
        <div :if={@current_page} class="max-w-3xl mx-auto py-8 px-8">
          <div class="flex items-center justify-between mb-8">
            <h1 class="text-3xl font-bold">{@current_page.title}</h1>
            <div class="flex items-center gap-2">
              <button
                :if={@current_scope && @current_scope.user && @is_starred}
                phx-click="unstar"
                class="btn btn-ghost btn-sm rounded-full"
              >
                <.icon name="hero-star-solid" class="size-4 text-amber-400" />
                {@star_count}
              </button>
              <button
                :if={@current_scope && @current_scope.user && !@is_starred}
                phx-click="star"
                class="btn btn-ghost btn-sm rounded-full"
              >
                <.icon name="hero-star" class="size-4" />
                {@star_count}
              </button>
              <span
                :if={!@current_scope || !@current_scope.user}
                class="flex items-center gap-1 text-sm text-base-content/50"
              >
                <.icon name="hero-star" class="size-4" />
                {@star_count}
              </span>
              <button phx-click="scroll-to-comments" class="btn btn-ghost btn-sm rounded-full">
                <.icon name="hero-chat-bubble-left" class="size-4" />
                {@comment_count}
              </button>
              <.link
                :if={@suggestions_enabled && @is_page_owner}
                navigate={~p"/c/#{@community.name}/#{@current_page.slug}/proposals"}
                class="btn btn-ghost btn-sm rounded-full"
              >
                <.icon name="hero-document-text" class="size-4" /> Proposals
                <span :if={@pending_count > 0} class="badge badge-sm badge-primary rounded-full">
                  {@pending_count}
                </span>
              </.link>
              <.link
                :if={@is_page_owner}
                navigate={~p"/c/#{@community.name}/#{@current_page.slug}/edit"}
                class="btn btn-primary btn-sm rounded-full"
              >
                Edit
              </.link>
            </div>
          </div>

          <div class="prose max-w-none">
            <%= for section <- @sections do %>
              <div id={"section-#{section.id}"} class="scroll-mt-8 relative group">
                <.link
                  :if={
                    @suggestions_enabled && @current_scope && @current_scope.user && !@is_page_owner
                  }
                  navigate={
                    ~p"/c/#{@community.name}/#{@current_page.slug}/sections/#{section.id}/propose"
                  }
                  class="btn btn-ghost btn-xs rounded-full absolute right-0 top-6 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  Propose Edit
                </.link>
                <.render_block
                  :for={block <- section.content || []}
                  block={block}
                  highlight={@search_query}
                />
              </div>
            <% end %>
          </div>

          <.live_component
            module={AtlasWeb.CommentsSection}
            id="comments"
            comments={@comments}
            current_user={@current_scope && @current_scope.user}
            threaded={true}
            is_owner={@is_page_owner}
          />
        </div>

        <div :if={!@current_page} class="flex items-center justify-center h-full">
          <.empty_state
            href={~p"/c/#{@community.name}/new"}
            link_text="Create the first page"
          >
            No pages yet.
          </.empty_state>
        </div>
      </main>
    </div>
    """
  end
end
