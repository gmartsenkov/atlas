defmodule AtlasWeb.CommunitySearch do
  @moduledoc false
  use AtlasWeb, :live_component

  alias Atlas.Communities

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:query, fn -> "" end)
      |> assign_new(:results, fn -> [] end)
      |> assign_new(:open, fn -> false end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-64" phx-click-away="close" phx-target={@myself}>
      <label class="flex items-center gap-2 px-3 h-8 bg-base-100 border border-primary/50 rounded-full">
        <.icon name="hero-magnifying-glass-micro" class="size-4 text-base-content/40 shrink-0" />
        <input
          type="text"
          placeholder="Search communities..."
          value={@query}
          phx-keyup="search"
          phx-focus="open"
          phx-target={@myself}
          phx-debounce="200"
          class="grow bg-transparent border-none outline-none focus:ring-0 p-0 text-sm min-w-0"
          autocomplete="off"
        />
      </label>

      <div
        :if={@open && (@results != [] || @query != "")}
        class="absolute left-0 right-0 mt-1.5 bg-base-100 border border-primary/50 rounded-2xl shadow-xl z-[100] overflow-hidden"
      >
        <div :if={@results != []} class="max-h-72 overflow-y-auto py-1">
          <.link
            :for={community <- @results}
            navigate={~p"/c/#{community.name}"}
            class="flex items-center gap-3 px-3 py-2 hover:bg-base-200 transition-colors"
          >
            <.community_icon icon={community.icon} size={:sm} />
            <div class="flex-1 min-w-0">
              <div class="font-medium text-sm truncate">{community.name}</div>
              <div :if={community.description} class="text-xs text-base-content/50 truncate">
                {community.description}
              </div>
            </div>
          </.link>
        </div>

        <div
          :if={@results == [] && @query != ""}
          class="px-3 py-3 text-center text-sm text-base-content/50"
        >
          No communities found
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        []
      else
        Communities.search_communities(query, limit: 6).items
      end

    {:noreply, assign(socket, query: query, results: results, open: true)}
  end

  def handle_event("open", _params, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :open, false)}
  end
end
