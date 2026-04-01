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
          class="input w-full bg-base-200 rounded-xl"
        />
      </form>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <.link
          :for={community <- @communities}
          navigate={~p"/c/#{community.slug}"}
          class="card bg-base-200 hover:bg-base-300 transition cursor-pointer rounded-2xl"
        >
          <div class="card-body">
            <div class="flex items-center gap-3">
              <img
                :if={community.icon}
                src={community.icon}
                alt=""
                class="w-10 h-10 rounded-lg object-cover shrink-0"
              />
              <div
                :if={!community.icon}
                class="w-10 h-10 rounded-lg bg-base-300 flex items-center justify-center shrink-0"
              >
                <.icon name="hero-rectangle-group" class="w-5 h-5 text-base-content/40" />
              </div>
              <h2 class="card-title">{community.name}</h2>
            </div>
            <p :if={community.description} class="text-base-content/60 text-sm">
              {community.description}
            </p>
            <div class="card-actions justify-end mt-2">
              <span class="badge badge-outline rounded-full">
                {community.member_count} {if community.member_count == 1, do: "member", else: "members"}
              </span>
            </div>
          </div>
        </.link>
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
