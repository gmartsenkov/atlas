defmodule AtlasWeb.CommunityLive.About do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        {:ok,
         assign(socket,
           page_title: "About — #{community.name}",
           community: community,
           page_count: length(community.pages)
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto py-8 px-8">
      <.back_link navigate={~p"/c/#{@community.name}"}>{@community.name}</.back_link>

      <%!-- Community Info Card --%>
      <div class="border border-base-300 rounded-xl p-6 mb-8 bg-base-200/30">
        <div class="flex items-start gap-4 mb-4">
          <.community_icon icon={@community.icon} size={:lg} />
          <div>
            <h1 class="text-2xl font-bold">{@community.name}</h1>
            <p :if={@community.description} class="text-base-content/60 mt-1">
              {@community.description}
            </p>
          </div>
        </div>

        <div class="text-sm text-base-content/50 mb-4">
          Created by
          <.link
            navigate={~p"/u/#{@community.owner.nickname}"}
            class="text-base-content/70 font-medium hover:text-base-content transition"
          >
            {@community.owner.nickname}
          </.link>
          · {Calendar.strftime(@community.inserted_at, "%b %d, %Y")}
        </div>

        <div class="flex gap-4 text-sm text-base-content/60">
          <span class="font-medium">{@page_count} pages</span>
        </div>
      </div>
    </div>
    """
  end
end
