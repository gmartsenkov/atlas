defmodule AtlasWeb.CommunitySidebar do
  use AtlasWeb, :live_component

  alias Atlas.Communities

  @impl true
  def update(assigns, socket) do
    old_auto = socket.assigns[:auto_expand_collection_id]

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:search_query, fn -> "" end)
      |> assign_new(:search_results, fn -> nil end)
      |> assign_new(:expanded_collections, fn -> MapSet.new() end)

    socket =
      if assigns[:auto_expand_collection_id] != old_auto do
        case assigns[:auto_expand_collection_id] do
          nil -> assign(socket, expanded_collections: MapSet.new())
          id -> assign(socket, expanded_collections: MapSet.new([id]))
        end
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle-collection", %{"id" => id}, socket) do
    case Integer.parse(id) do
      {id, ""} ->
        expanded = socket.assigns.expanded_collections

        expanded =
          if MapSet.member?(expanded, id),
            do: MapSet.delete(expanded, id),
            else: MapSet.put(expanded, id)

        {:noreply, assign(socket, expanded_collections: expanded)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if query == "" do
      send(self(), {:sidebar, :search_changed, ""})
      {:noreply, assign(socket, search_query: "", search_results: nil)}
    else
      results = Communities.search_community_content(socket.assigns.community, query)
      send(self(), {:sidebar, :search_changed, query})
      {:noreply, assign(socket, search_query: query, search_results: results)}
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
    <aside class={[
      "w-72 shrink-0 border-r border-base-300 flex flex-col bg-base-200",
      "absolute inset-y-0 left-0 z-30 lg:static lg:z-auto",
      "transition-transform duration-200 ease-in-out",
      if(@sidebar_open, do: "translate-x-0", else: "-translate-x-full lg:translate-x-0")
    ]}>
      <%!-- Search --%>
      <div class="px-4 pt-4 pb-2">
        <form phx-change="search" phx-submit="search" phx-target={@myself}>
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
                phx-target={@myself}
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
    """
  end
end
