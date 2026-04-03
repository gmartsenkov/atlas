defmodule AtlasWeb.CommunitiesLive.Index do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(_params, _session, socket) do
    communities = Communities.list_communities()

    {:ok,
     assign(socket,
       page_title: "Browse Communities",
       communities: communities,
       query: ""
     )}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    communities = Communities.search_communities(query)
    {:noreply, assign(socket, communities: communities, query: query)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold">Communities</h1>
          <p class="text-base-content/60 mt-1">Browse and discover communities on Atlas.</p>
        </div>
        <.link navigate={~p"/communities/new"} class="btn btn-primary rounded-full">
          New Community
        </.link>
      </div>

      <form phx-change="search" class="mb-8">
        <input
          type="search"
          name="query"
          value={@query}
          placeholder="Search communities..."
          autofocus
          phx-debounce="200"
          class="input w-full rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
        />
      </form>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <.community_card :for={community <- @communities} community={community} />
      </div>

      <div :if={@communities == [] && @query != ""} class="text-center py-16 text-base-content/40">
        <p class="text-lg">No communities match "{@query}"</p>
      </div>

      <div :if={@communities == [] && @query == ""} class="text-center py-16 text-base-content/40">
        <p class="text-lg">No communities yet — be the first to start one.</p>
        <.link navigate={~p"/communities/new"} class="btn btn-primary btn-sm rounded-full mt-4">
          Create the first community
        </.link>
      </div>
    </div>
    """
  end
end
