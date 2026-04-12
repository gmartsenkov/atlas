defmodule AtlasWeb.CommunitiesLive.Index do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @per_page 18

  @impl true
  def mount(_params, _session, socket) do
    page = Communities.list_communities(limit: @per_page)

    {:ok,
     socket
     |> assign(page_title: "Browse Communities", page: page, query: "")
     |> stream(:communities, page.items)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    page = Communities.search_communities(query, limit: @per_page)

    {:noreply,
     socket
     |> assign(page: page, query: query)
     |> stream(:communities, page.items, reset: true)}
  end

  def handle_event("load-more", _params, socket) do
    %{page: prev, query: query} = socket.assigns
    new_offset = prev.offset + prev.limit

    page =
      if query == "",
        do: Communities.list_communities(limit: @per_page, offset: new_offset),
        else: Communities.search_communities(query, limit: @per_page, offset: new_offset)

    {:noreply,
     socket
     |> assign(page: page)
     |> stream(:communities, page.items)}
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
          <.icon name="hero-plus" class="size-4" /> New Community
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

      <div
        id="communities-list"
        phx-update="stream"
        class="flex flex-col"
      >
        <div :for={{dom_id, community} <- @streams.communities} id={dom_id}>
          <.community_card community={community} />
        </div>
      </div>

      <.load_more page={@page} on_load_more="load-more" />

      <.empty_state :if={@page.total == 0 && @query != ""}>
        No communities match "{@query}"
      </.empty_state>

      <.empty_state
        :if={@page.total == 0 && @query == ""}
        href={~p"/communities/new"}
        link_text="Create the first community"
      >
        No communities yet — be the first to start one.
      </.empty_state>
    </div>
    """
  end
end
