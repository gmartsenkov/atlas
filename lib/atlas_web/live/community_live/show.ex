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
    community = Communities.get_community_by_name!(name)
    current_user = current_user(socket)

    is_member =
      if current_user,
        do: Communities.member?(current_user, community),
        else: false

    is_owner =
      if current_user,
        do: community.owner_id == current_user.id,
        else: false

    pending_proposal_count = Communities.count_community_pending_proposals(community)

    {:ok,
     assign(socket,
       full_bleed: true,
       community: community,
       pages: community.pages,
       is_member: is_member,
       is_owner: is_owner,
       pending_proposal_count: pending_proposal_count,
       search_query: "",
       search_results: nil,
       sidebar_open: false
     )}
  end

  defp current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: %{id: _} = user}} -> user
      _ -> nil
    end
  end

  @impl true
  def handle_params(%{"page_slug" => page_slug} = params, _uri, socket) do
    page = Communities.get_page_by_slugs!(socket.assigns.community.name, page_slug)

    pending_count =
      if socket.assigns.is_owner,
        do: Communities.count_pending_proposals(page),
        else: 0

    is_page_owner =
      case current_user(socket) do
        nil -> false
        user -> page.owner_id == user.id
      end

    socket =
      socket
      |> assign(
        page_title: "#{page.title} — #{socket.assigns.community.name}",
        current_page: page,
        sections: page.sections,
        headings: extract_headings(page.sections),
        pending_count: pending_count,
        is_page_owner: is_page_owner,
        sidebar_open: false
      )

    socket =
      case params["scroll_to"] do
        nil -> socket
        id -> push_event(socket, "scroll-to", %{id: id})
      end

    {:noreply, socket}
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
           is_page_owner: false
         )}
    end
  end

  @impl true
  def handle_event("join", _params, socket) do
    user = current_user(socket)
    community = socket.assigns.community

    case Communities.join_community(user, community) do
      {:ok, _} -> {:noreply, assign(socket, is_member: true)}
      {:error, _} -> {:noreply, socket}
    end
  end

  def handle_event("leave", _params, socket) do
    user = current_user(socket)
    community = socket.assigns.community
    Communities.leave_community(user, community)
    {:noreply, assign(socket, is_member: false)}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, sidebar_open: !socket.assigns.sidebar_open)}
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
          <.link
            navigate={~p"/"}
            class="text-base-content/40 hover:text-base-content transition shrink-0"
          >
            <.icon name="hero-arrow-left" class="size-4" />
          </.link>
          <img
            :if={@community.icon}
            src={@community.icon}
            alt=""
            class="w-7 h-7 rounded-md object-cover shrink-0"
          />
          <div
            :if={!@community.icon}
            class="w-7 h-7 rounded-md bg-base-300 flex items-center justify-center shrink-0"
          >
            <.icon name="hero-rectangle-group" class="w-3.5 h-3.5 text-base-content/40" />
          </div>
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
            <span :if={@pending_proposal_count > 0} class="badge badge-sm badge-primary rounded-full">
              {@pending_proposal_count}
            </span>
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
            :if={@current_scope && @current_scope.user && @is_member}
            phx-click="leave"
            class="btn btn-ghost btn-xs rounded-full"
          >
            <.icon name="hero-arrow-right-start-on-rectangle" class="size-3.5" /> Leave
          </button>
        </div>
      </div>
    </div>

    <div class="flex h-[calc(100vh-4rem-3.5rem)] relative overflow-hidden">
      <%!-- Mobile sidebar backdrop --%>
      <div
        :if={@sidebar_open}
        phx-click="toggle_sidebar"
        class="absolute inset-0 bg-black/30 z-20 lg:hidden"
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
              class="input input-sm input-bordered w-full"
              autocomplete="off"
            />
          </form>
        </div>

        <%= if @search_results do %>
          <%!-- Search results --%>
          <div class="flex-1 overflow-y-auto px-3 pb-4">
            <div class="text-[11px] font-semibold text-base-content/40 uppercase tracking-wider px-2 mb-2">
              Results ({length(@search_results)})
            </div>
            <div :if={@search_results == []} class="px-2 text-sm text-base-content/50">
              No results found.
            </div>
            <div class="space-y-1">
              <.link
                :for={result <- @search_results}
                patch={~p"/c/#{@community.name}/#{result.page_slug}?scroll_to=section-#{result.section_id}"}
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
            <h3 class="text-[11px] font-semibold text-base-content/40 uppercase tracking-wider">
              Pages
            </h3>
          </div>

          <nav id="sections-nav" phx-hook="ScrollTo" class="flex-1 overflow-y-auto px-3 pb-4">
            <div class="space-y-0.5">
              <%= for page <- @pages do %>
                <.link
                  patch={~p"/c/#{@community.name}/#{page.slug}"}
                  class={[
                    "block px-3 py-2 rounded-md text-sm truncate transition",
                    if(@current_page && @current_page.id == page.id,
                      do: "bg-base-content/10 font-medium text-base-content",
                      else: "text-base-content/70 hover:bg-base-content/5 hover:text-base-content"
                    )
                  ]}
                >
                  {page.title}
                </.link>

                <%= if @current_page && @current_page.id == page.id && @headings != [] do %>
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
              <% end %>
            </div>
          </nav>
        <% end %>

        <div class="px-4 py-3 border-t border-base-300/60">
          <.link
            navigate={~p"/c/#{@community.name}/new"}
            class="btn btn-primary btn-sm w-full rounded-full"
          >
            New Page
          </.link>
        </div>
      </aside>

      <%!-- Main content --%>
      <main id="page-content" phx-hook="ScrollToTarget" class="flex-1 overflow-y-auto">
        <div :if={@current_page} class="max-w-3xl mx-auto py-8 px-8">
          <div class="flex items-center justify-between mb-8">
            <h1 class="text-3xl font-bold">{@current_page.title}</h1>
            <div class="flex items-center gap-2">
              <.link
                :if={@is_page_owner}
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
                  :if={@current_scope && @current_scope.user && !@is_page_owner}
                  navigate={
                    ~p"/c/#{@community.name}/#{@current_page.slug}/sections/#{section.id}/propose"
                  }
                  class="btn btn-ghost btn-xs rounded-full absolute right-0 top-6 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  Propose Edit
                </.link>
                <.render_block :for={block <- section.content || []} block={block} highlight={@search_query} />
              </div>
            <% end %>
          </div>
        </div>

        <div :if={!@current_page} class="flex items-center justify-center h-full text-base-content/40">
          <div class="text-center">
            <p class="text-lg mb-4">No pages yet.</p>
            <.link
              navigate={~p"/c/#{@community.name}/new"}
              class="btn btn-primary btn-sm rounded-full"
            >
              Create the first page
            </.link>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
