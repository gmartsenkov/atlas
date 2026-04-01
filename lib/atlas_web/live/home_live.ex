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
    <%!-- Hero --%>
    <div class="text-center max-w-3xl mx-auto mb-20">
      <h1 class="text-5xl font-extrabold tracking-tight sm:text-6xl">
        Shared knowledge,
        <span class="text-primary">built together</span>
      </h1>
      <p class="mt-6 text-lg text-base-content/60 max-w-2xl mx-auto">
        Atlas is a collaborative wiki platform where communities organize, write, and share
        knowledge — all in one place.
      </p>
      <div class="mt-8 flex justify-center gap-3">
        <.link navigate={~p"/communities/new"} class="btn btn-primary rounded-full">
          Create a Community
        </.link>
        <.link navigate={~p"/communities"} class="btn btn-ghost rounded-full">Browse Communities</.link>
      </div>
    </div>

    <%!-- Features --%>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto mb-20">
      <div class="text-center">
        <div class="bg-primary/10 w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-3">
          <.icon name="hero-user-group" class="w-6 h-6 text-primary" />
        </div>
        <h3 class="font-semibold text-lg">Community-driven</h3>
        <p class="text-sm text-base-content/60 mt-1">
          Create spaces for any topic and invite others to contribute.
        </p>
      </div>
      <div class="text-center">
        <div class="bg-primary/10 w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-3">
          <.icon name="hero-pencil-square" class="w-6 h-6 text-primary" />
        </div>
        <h3 class="font-semibold text-lg">Rich editing</h3>
        <p class="text-sm text-base-content/60 mt-1">
          A powerful block editor for writing beautiful, structured pages.
        </p>
      </div>
      <div class="text-center">
        <div class="bg-primary/10 w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-3">
          <.icon name="hero-bolt" class="w-6 h-6 text-primary" />
        </div>
        <h3 class="font-semibold text-lg">Real-time</h3>
        <p class="text-sm text-base-content/60 mt-1">
          Changes appear instantly — no refreshing, no waiting.
        </p>
      </div>
    </div>

    <%!-- Communities --%>
    <div id="communities" class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-2xl font-bold">Communities</h2>
        <.link navigate={~p"/communities/new"} class="btn btn-primary btn-sm rounded-full">
          New Community
        </.link>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <.link
          :for={community <- @communities}
          navigate={~p"/c/#{community.name}"}
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

      <div :if={@communities == []} class="text-center py-16 text-base-content/40">
        <p class="text-lg">No communities yet — be the first to start one.</p>
        <.link navigate={~p"/communities/new"} class="btn btn-primary btn-sm rounded-full mt-4">
          Create the first community
        </.link>
      </div>
    </div>
    """
  end
end
