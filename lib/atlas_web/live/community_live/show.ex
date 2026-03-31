defmodule AtlasWeb.CommunityLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_slug" => slug}, _session, socket) do
    community = Communities.get_community_by_slug!(slug)

    {:ok,
     assign(socket,
       page_title: community.name,
       community: community
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto">
      <div class="mb-8">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:text-base-content">
          &larr; Communities
        </.link>
      </div>

      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold">{@community.name}</h1>
          <p :if={@community.description} class="text-base-content/60 mt-1">
            {@community.description}
          </p>
        </div>
        <.link navigate={~p"/c/#{@community.slug}/new"} class="btn btn-primary">
          New Page
        </.link>
      </div>

      <div class="space-y-2">
        <.link
          :for={page <- @community.pages}
          navigate={~p"/c/#{@community.slug}/#{page.slug}"}
          class="block p-4 rounded-lg bg-base-200 hover:bg-base-300 transition"
        >
          <span class="font-medium">{page.title}</span>
        </.link>
      </div>

      <div :if={@community.pages == []} class="text-center py-20 text-base-content/40">
        <p class="text-lg">No pages yet.</p>
        <.link navigate={~p"/c/#{@community.slug}/new"} class="btn btn-primary btn-sm mt-4">
          Create the first page
        </.link>
      </div>
    </div>
    """
  end
end
