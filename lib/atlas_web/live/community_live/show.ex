defmodule AtlasWeb.CommunityLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  import AtlasWeb.BlockRenderer

  defp extract_headings(sections) do
    sections
    |> Enum.sort_by(& &1.sort_order)
    |> Enum.flat_map(fn section ->
      (section.content || [])
      |> Enum.filter(fn block ->
        block["type"] == "heading" and block["id"]
      end)
      |> Enum.map(fn block ->
        %{
          id: block["id"],
          text: get_in(block, ["content", Access.at(0), "text"]) || "Untitled",
          level: get_in(block, ["props", "level"]) || 1
        }
      end)
    end)
  end

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        {:ok, redirect(socket, to: ~p"/404")}

      {:ok, community} ->
        current_user = current_user(socket)

        is_member =
          if current_user,
            do: Communities.member?(current_user, community),
            else: false

        is_owner =
          if current_user,
            do: community.owner_id == current_user.id,
            else: false

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
           expanded_collections: MapSet.new(),
           search_query: "",
           search_results: nil,
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

    is_page_owner =
      case current_user(socket) do
        nil -> false
        user -> page.owner_id == user.id
      end

    current_user = current_user(socket)

    is_starred =
      if current_user,
        do: Communities.page_starred?(current_user, page),
        else: false

    star_count = Communities.count_page_stars(page)

    comments = Communities.list_page_comments(page)
    comment_count = Communities.count_page_comments(page)

    socket =
      socket
      |> assign(
        page_title: "#{page.title} — #{socket.assigns.community.name}",
        current_page: page,
        sections: page.sections,
        headings: extract_headings(page.sections),
        pending_count: pending_count,
        is_page_owner: is_page_owner,
        is_starred: is_starred,
        star_count: star_count,
        sidebar_open: false,
        comments: comments,
        comment_count: comment_count,
        comment_text: "",
        reply_text: "",
        reply_to: nil
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
        {:noreply, push_navigate(socket, to: ~p"/404")}

      {:ok, page} ->
        expanded =
          if page.collection_id,
            do: MapSet.new([page.collection_id]),
            else: MapSet.new()

        {:noreply,
         socket
         |> assign(expanded_collections: expanded)
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
           comment_count: 0,
           comment_text: "",
           reply_text: "",
           reply_to: nil
         )}
    end
  end

  defp require_user(socket, fun) do
    case current_user(socket) do
      nil -> {:noreply, socket}
      user -> fun.(user)
    end
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
        :ok -> {:noreply, assign(socket, is_member: false)}
        {:error, :owner_cannot_leave} -> {:noreply, socket}
      end
    end)
  end

  def handle_event("star", _params, socket) do
    require_user(socket, fn user ->
      page = socket.assigns.current_page

      case Communities.star_page(user, page) do
        {:ok, _} ->
          {:noreply, assign(socket, is_starred: true, star_count: socket.assigns.star_count + 1)}

        {:error, _} ->
          {:noreply, socket}
      end
    end)
  end

  def handle_event("unstar", _params, socket) do
    require_user(socket, fn user ->
      page = socket.assigns.current_page
      Communities.unstar_page(user, page)
      {:noreply, assign(socket, is_starred: false, star_count: socket.assigns.star_count - 1)}
    end)
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
  end

  def handle_event("toggle-collection", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded = socket.assigns.expanded_collections

    expanded =
      if MapSet.member?(expanded, id),
        do: MapSet.delete(expanded, id),
        else: MapSet.put(expanded, id)

    {:noreply, assign(socket, expanded_collections: expanded)}
  end

  def handle_event("scroll-to-comments", _params, socket) do
    {:noreply, push_event(socket, "scroll-to", %{id: "comments"})}
  end

  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if query == "" do
      {:noreply, assign(socket, search_query: "", search_results: nil)}
    else
      results = Communities.search_community_content(socket.assigns.community, query)
      {:noreply, assign(socket, search_query: query, search_results: results)}
    end
  end

  def handle_event("update-page-comment", %{"value" => value}, socket) do
    {:noreply, assign(socket, comment_text: value)}
  end

  def handle_event("add-page-comment", _params, socket) do
    user = current_user(socket)
    page = socket.assigns.current_page
    body = String.trim(socket.assigns.comment_text)

    if user && body != "" do
      case Communities.add_page_comment(page, user, %{body: body}) do
        {:ok, _comment} ->
          {:noreply,
           assign(socket,
             comments: Communities.list_page_comments(page),
             comment_count: Communities.count_page_comments(page),
             comment_text: ""
           )}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("start-reply", %{"id" => id}, socket) do
    {:noreply, assign(socket, reply_to: String.to_integer(id), reply_text: "")}
  end

  def handle_event("cancel-reply", _params, socket) do
    {:noreply, assign(socket, reply_to: nil, reply_text: "")}
  end

  def handle_event("update-reply", %{"value" => value}, socket) do
    {:noreply, assign(socket, reply_text: value)}
  end

  def handle_event("add-reply", _params, socket) do
    user = current_user(socket)
    page = socket.assigns.current_page
    body = String.trim(socket.assigns.reply_text)

    with true <- user != nil && body != "",
         {:ok, parent} <- Communities.get_page_comment(socket.assigns.reply_to),
         {:ok, _reply} <- Communities.reply_to_page_comment(page, parent, user, %{body: body}) do
      {:noreply,
       assign(socket,
         comments: Communities.list_page_comments(page),
         comment_count: Communities.count_page_comments(page),
         reply_to: nil,
         reply_text: ""
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("delete-comment", %{"id" => id}, socket) do
    user = current_user(socket)
    page = socket.assigns.current_page

    with {:ok, comment} <- Communities.get_page_comment(id),
         true <- user != nil && (comment.author_id == user.id || page.owner_id == user.id) do
      Communities.delete_page_comment(comment)

      {:noreply,
       assign(socket,
         comments: Communities.list_page_comments(page),
         comment_count: Communities.count_page_comments(page)
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  defp sidebar_page_link(assigns) do
    ~H"""
    <div>
      <.link
        patch={~p"/c/#{@community.name}/#{@page.slug}"}
        class={[
          "block px-3 py-2 rounded-md text-sm truncate transition",
          if(@current_page && @current_page.id == @page.id,
            do: "bg-base-content/10 font-medium text-base-content",
            else: "text-base-content/70 hover:bg-base-content/5 hover:text-base-content"
          )
        ]}
      >
        {@page.title}
      </.link>

      <%= if @current_page && @current_page.id == @page.id && @headings != [] do %>
        <div class="ml-4 my-1.5 pl-3 border-l-2 border-base-content/10 space-y-0.5">
          <a
            :for={heading <- @headings}
            href={"##{heading.id}"}
            class={[
              "block py-1 text-sm truncate transition rounded-sm hover:text-base-content",
              if(heading.level <= 2,
                do: "text-base-content/50",
                else: "text-base-content/40 ml-2"
              )
            ]}
          >
            {heading.text}
          </a>
        </div>
      <% end %>
    </div>
    """
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
      <aside class={[
        "w-72 shrink-0 border-r border-base-300 flex flex-col bg-base-200",
        "absolute inset-y-0 left-0 z-30 lg:static lg:z-auto",
        "transition-transform duration-200 ease-in-out",
        if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full lg:translate-x-0")
      ]}>
        <%!-- Search --%>
        <div class="px-4 pt-4 pb-2">
          <form phx-change="search" phx-submit="search">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search pages..."
              phx-debounce="300"
              class="input input-sm input-bordered w-full rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
              autocomplete="off"
            />
          </form>
        </div>

        <%= if @search_results do %>
          <%!-- Search results --%>
          <div class="flex-1 overflow-y-auto px-3 pb-4">
            <.section_label class="px-2 mb-2">
              Results ({length(@search_results)})
            </.section_label>
            <div :if={@search_results == []} class="px-2 text-sm text-base-content/50">
              No results found.
            </div>
            <div class="space-y-1">
              <.link
                :for={result <- @search_results}
                patch={
                  ~p"/c/#{@community.name}/#{result.page_slug}?scroll_to=section-#{result.section_id}"
                }
                class="block px-3 py-2 rounded-md text-sm hover:bg-base-content/5 transition"
              >
                <div class="font-medium text-base-content truncate">{result.page_title}</div>
                <div class="text-xs text-base-content/40 mt-0.5 line-clamp-2">
                  {Phoenix.HTML.raw(result.snippet)}
                </div>
              </.link>
            </div>
          </div>
        <% else %>
          <%!-- Normal page list --%>
          <div class="px-5 pb-2">
            <.section_label>Pages</.section_label>
          </div>

          <nav id="sections-nav" phx-hook="ScrollTo" class="flex-1 overflow-y-auto px-3 pb-4">
            <%!-- Uncollected pages --%>
            <div class="space-y-0.5">
              <%= for page <- @uncollected_pages do %>
                <.sidebar_page_link
                  page={page}
                  community={@community}
                  current_page={@current_page}
                  headings={@headings}
                />
              <% end %>
            </div>

            <%!-- Collected pages by collection --%>
            <%= for {collection, coll_pages} <- @collected_pages do %>
              <div class="mt-3">
                <button
                  phx-click="toggle-collection"
                  phx-value-id={collection.id}
                  class="flex items-center gap-1 px-2 py-1 w-full cursor-pointer hover:bg-base-content/5 rounded-md transition"
                >
                  <.icon
                    name={
                      if MapSet.member?(@expanded_collections, collection.id),
                        do: "hero-chevron-down-mini",
                        else: "hero-chevron-right-mini"
                    }
                    class="size-3.5 text-base-content/40 shrink-0"
                  />
                  <.icon name="hero-folder" class="size-3.5 text-base-content/40 shrink-0" />
                  <span class="text-xs font-semibold text-base-content/50 uppercase tracking-wider truncate">
                    {collection.name}
                  </span>
                </button>
                <div
                  :if={MapSet.member?(@expanded_collections, collection.id)}
                  class="space-y-0.5 ml-2"
                >
                  <%= for page <- coll_pages do %>
                    <.sidebar_page_link
                      page={page}
                      community={@community}
                      current_page={@current_page}
                      headings={@headings}
                    />
                  <% end %>
                </div>
              </div>
            <% end %>
          </nav>
        <% end %>

        <div class="px-4 py-3 border-t border-base-300/60 space-y-2">
          <.link
            :if={@is_owner}
            navigate={~p"/c/#{@community.name}/new"}
            class="btn btn-primary btn-sm w-full rounded-full"
          >
            New Page
          </.link>
          <.link
            :if={@current_scope && @current_scope.user && !@is_owner && @suggestions_enabled}
            navigate={~p"/c/#{@community.name}/propose-page"}
            class="btn btn-outline btn-primary btn-sm w-full rounded-full"
          >
            Propose New Page
          </.link>
        </div>
      </aside>

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

          <%!-- Comments section --%>
          <div id="comments" class="mt-12 pt-8 border-t border-base-300 scroll-mt-4">
            <h2 class="text-lg font-semibold flex items-center gap-2 mb-6">
              <.icon name="hero-chat-bubble-left-right" class="size-5" /> Comments
              <span :if={@comment_count > 0} class="badge badge-sm rounded-full">
                {@comment_count}
              </span>
            </h2>

            <div :if={@comments == []} class="text-sm text-base-content/50 mb-6">
              No comments yet. Be the first to start a discussion.
            </div>

            <div class="space-y-4 mb-6">
              <%= for comment <- @comments do %>
                <div id={"comment-#{comment.id}"} class="p-3 rounded-lg bg-base-200/50">
                  <div class="flex items-center justify-between mb-1">
                    <div class="flex items-center gap-2 text-sm">
                      <.link
                        navigate={~p"/u/#{comment.author.nickname}"}
                        class="font-medium hover:underline"
                      >
                        {comment.author.nickname}
                      </.link>
                      <span class="text-base-content/40">
                        {Calendar.strftime(comment.inserted_at, "%b %d, %Y")}
                      </span>
                    </div>
                    <button
                      :if={
                        @current_scope && @current_scope.user &&
                          (@current_scope.user.id == comment.author_id || @is_page_owner)
                      }
                      phx-click="delete-comment"
                      phx-value-id={comment.id}
                      data-confirm="Delete this comment?"
                      class="btn btn-ghost btn-xs"
                    >
                      <.icon name="hero-trash" class="size-3.5" />
                    </button>
                  </div>
                  <p class="text-sm whitespace-pre-wrap">{comment.body}</p>
                  <button
                    :if={@current_scope && @current_scope.user}
                    phx-click="start-reply"
                    phx-value-id={comment.id}
                    class="text-xs text-base-content/50 hover:text-base-content mt-1 inline-flex items-center gap-1"
                  >
                    <.icon name="hero-chat-bubble-left" class="size-3" /> Reply
                  </button>

                  <%!-- Replies --%>
                  <div
                    :if={comment.replies != []}
                    class="mt-3 ml-4 pl-4 border-l-2 border-base-content/20 space-y-3"
                  >
                    <%= for reply <- comment.replies do %>
                      <div
                        id={"comment-#{reply.id}"}
                        class="p-3 rounded-lg"
                      >
                        <div class="flex items-center justify-between mb-1">
                          <div class="flex items-center gap-2 text-sm">
                            <.link
                              navigate={~p"/u/#{reply.author.nickname}"}
                              class="font-medium hover:underline"
                            >
                              {reply.author.nickname}
                            </.link>
                            <span class="text-base-content/40">
                              {Calendar.strftime(reply.inserted_at, "%b %d, %Y")}
                            </span>
                          </div>
                          <button
                            :if={
                              @current_scope && @current_scope.user &&
                                (@current_scope.user.id == reply.author_id || @is_page_owner)
                            }
                            phx-click="delete-comment"
                            phx-value-id={reply.id}
                            data-confirm="Delete this reply?"
                            class="btn btn-ghost btn-xs"
                          >
                            <.icon name="hero-trash" class="size-3.5" />
                          </button>
                        </div>
                        <p class="text-sm whitespace-pre-wrap">{reply.body}</p>
                      </div>
                    <% end %>
                  </div>

                  <%!-- Inline reply form --%>
                  <div :if={@reply_to == comment.id} class="mt-3 ml-8">
                    <textarea
                      phx-keyup="update-reply"
                      placeholder="Write a reply..."
                      rows="2"
                      class="w-full textarea text-sm rounded-2xl focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                    >{@reply_text}</textarea>
                    <div class="flex gap-2 mt-2">
                      <button phx-click="add-reply" class="btn btn-primary btn-xs rounded-full">
                        Reply
                      </button>
                      <button phx-click="cancel-reply" class="btn btn-ghost btn-xs rounded-full">
                        Cancel
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <%!-- New comment form --%>
            <div :if={@current_scope && @current_scope.user} class="mt-4">
              <textarea
                phx-keyup="update-page-comment"
                placeholder="Add a comment..."
                rows="3"
                class="w-full textarea text-sm rounded-2xl focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
              >{@comment_text}</textarea>
              <div class="flex justify-end mt-2">
                <button phx-click="add-page-comment" class="btn btn-primary btn-sm rounded-full">
                  Comment
                </button>
              </div>
            </div>

            <div
              :if={!@current_scope || !@current_scope.user}
              class="text-sm text-base-content/50 mt-4"
            >
              <.link navigate={~p"/users/log-in"} class="link link-primary">Log in</.link>
              to join the discussion.
            </div>
          </div>
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
