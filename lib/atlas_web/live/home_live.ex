defmodule AtlasWeb.HomeLive do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(_params, _session, socket) do
    communities = Communities.list_communities()
    {:ok, assign(socket, page_title: "Communities", communities: communities)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold">Communities</h1>
          <p class="text-base-content/60 mt-1">Browse and contribute to community knowledge bases</p>
        </div>
        <.link navigate={~p"/communities/new"} class="btn btn-primary">
          New Community
        </.link>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <.link
          :for={community <- @communities}
          navigate={~p"/c/#{community.slug}"}
          class="card bg-base-200 hover:bg-base-300 transition cursor-pointer"
        >
          <div class="card-body">
            <h2 class="card-title">{community.name}</h2>
            <p :if={community.description} class="text-base-content/60 text-sm">
              {community.description}
            </p>
            <div class="card-actions justify-end mt-2">
              <span class="badge badge-outline">
                {length(community.pages)} {if length(community.pages) == 1, do: "page", else: "pages"}
              </span>
            </div>
          </div>
        </.link>
      </div>

      <div :if={@communities == []} class="text-center py-20 text-base-content/40">
        <p class="text-lg">No communities yet.</p>
        <.link navigate={~p"/communities/new"} class="btn btn-primary btn-sm mt-4">
          Create the first one
        </.link>
      </div>
    </div>
    """
  end
end
