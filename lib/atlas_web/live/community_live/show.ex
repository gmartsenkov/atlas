defmodule AtlasWeb.CommunityLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Communities
  import AtlasWeb.BlockRenderer

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

    {:ok,
     assign(socket,
       full_bleed: true,
       community: community,
       pages: community.pages,
       is_member: is_member,
       is_owner: is_owner,
       search_query: "",
       search_results: nil
     )}
  end

  defp current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: %{id: _} = user}} -> user
      _ -> nil
    end
  end

  @impl true
  def handle_params(%{"page_slug" => page_slug}, _uri, socket) do
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

    {:noreply,
     assign(socket,
       page_title: "#{page.title} — #{socket.assigns.community.name}",
       current_page: page,
       sections: page.sections,
       pending_count: pending_count,
       is_page_owner: is_page_owner
     )}
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
    <div class="border-b border-base-300 bg-base-200/30 px-4 sm:px-6">
      <div class="flex items-center justify-between h-14">
        <div class="flex items-center gap-3 min-w-0">
          <.link navigate={~p"/"} class="text-base-content/40 hover:text-base-content transition shrink-0">
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
            by {@community.owner.nickname}
          </span>
        </div>
        <div class="flex items-center gap-2 shrink-0">
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
            Join
          </button>
          <button
            :if={@current_scope && @current_scope.user && @is_member}
            phx-click="leave"
            class="btn btn-ghost btn-xs rounded-full"
          >
            Leave
          </button>
        </div>
      </div>
    </div>

    <div class="flex h-[calc(100vh-4rem-3.5rem)]">
      <%!-- Sidebar --%>
      <aside class="w-72 shrink-0 border-r border-base-300 flex flex-col bg-base-200/30">

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
                patch={"#{~p"/c/#{@community.name}/#{result.page_slug}"}#section-#{result.section_id}"}
                class="block px-3 py-2 rounded-md text-sm hover:bg-base-content/5 transition"
              >
                <div class="font-medium text-base-content truncate">{result.page_title}</div>
                <div class="text-xs text-base-content/50 truncate">{result.section_title}</div>
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

                <%= if @current_page && @current_page.id == page.id && @sections != [] do %>
                  <div class="ml-4 my-1.5 pl-3 border-l-2 border-base-content/10 space-y-0.5">
                    <a
                      :for={section <- @sections}
                      href={"#section-#{section.id}"}
                      class="block py-1 text-sm text-base-content/50 truncate transition rounded-sm hover:text-base-content"
                    >
                      {section.title}
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
      <main class="flex-1 overflow-y-auto">
        <div :if={@current_page} class="max-w-3xl mx-auto py-8 px-8">
          <div class="flex items-center justify-between mb-8">
            <h1 class="text-3xl font-bold">{@current_page.title}</h1>
            <div class="flex items-center gap-2">
              <.link
                :if={@is_page_owner}
                navigate={~p"/c/#{@community.name}/#{@current_page.slug}/proposals"}
                class="btn btn-ghost btn-sm rounded-full"
              >
                <.icon name="hero-document-text" class="size-4" />
                Proposals
                <span :if={@pending_count > 0} class="badge badge-sm badge-primary rounded-full">{@pending_count}</span>
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
                  navigate={~p"/c/#{@community.name}/#{@current_page.slug}/sections/#{section.id}/propose"}
                  class="btn btn-ghost btn-xs rounded-full absolute right-0 top-6 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  Propose Edit
                </.link>
                <.render_block :for={block <- section.content || []} block={block} />
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
