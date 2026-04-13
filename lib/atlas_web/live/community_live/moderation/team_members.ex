defmodule AtlasWeb.CommunityLive.Moderation.TeamMembers do
  @moduledoc false
  use AtlasWeb, :live_view

  alias Atlas.Communities
  import AtlasWeb.CommunityLive.Moderation

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    community = socket.assigns.community
    page = Communities.list_community_members(community, limit: @per_page)

    {:ok,
     socket
     |> assign(
       page_title: "Members - #{community.name}",
       member_search: "",
       members_page: page
     )
     |> stream(:members, page.items)}
  end

  @impl true
  def handle_event("search-members", %{"value" => query}, socket) do
    community = socket.assigns.community
    page = Communities.list_community_members(community, search: query, limit: @per_page)

    {:noreply,
     socket
     |> assign(member_search: query, members_page: page)
     |> stream(:members, page.items, reset: true)}
  end

  def handle_event("load-more-members", _params, socket) do
    %{members_page: prev, community: community, member_search: search} = socket.assigns
    new_offset = prev.offset + prev.limit

    page =
      Communities.list_community_members(community,
        search: search,
        limit: @per_page,
        offset: new_offset
      )

    {:noreply,
     socket
     |> assign(members_page: page)
     |> stream(:members, page.items)}
  end

  def handle_event("toggle-moderator", %{"user-id" => user_id}, socket) do
    community = socket.assigns.community
    {user_id, ""} = Integer.parse(user_id)

    member =
      Enum.find(socket.assigns.members_page.items, &(&1.user_id == user_id))

    {:noreply, maybe_toggle_role(socket, community, member)}
  end

  defp maybe_toggle_role(socket, _community, nil), do: socket

  defp maybe_toggle_role(socket, community, member) when member.user_id == community.owner_id,
    do: socket

  defp maybe_toggle_role(socket, community, member) do
    new_role = if member.role == "moderator", do: "member", else: "moderator"
    {:ok, _} = Communities.set_member_role(community, member.user_id, new_role)

    page =
      Communities.list_community_members(community,
        search: socket.assigns.member_search,
        limit: @per_page
      )

    socket
    |> assign(members_page: page)
    |> stream(:members, page.items, reset: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mod_layout
      community={@community}
      live_action={:members}
      is_owner={@is_owner}
      pending_count={@pending_count}
      moderated_communities={@moderated_communities}
    >
      <div class="max-w-3xl mx-auto">
        <h1 class="text-2xl font-bold mb-4">Mods & Members</h1>

        <div class="mb-6">
          <input
            type="text"
            name="search"
            value={@member_search}
            placeholder="Search members by nickname..."
            phx-keyup="search-members"
            phx-debounce="300"
            autocomplete="off"
            class="input input-bordered w-full max-w-sm rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
        </div>

        <div :if={@members_page.total == 0} class="text-base-content/50 py-8 text-center">
          No members found.
        </div>

        <div id="mod-members-list" phx-update="stream" class="space-y-2">
          <div :for={{dom_id, member} <- @streams.members} id={dom_id}>
            <.member_row member={member} community={@community} />
          </div>
        </div>

        <.load_more page={@members_page} on_load_more="load-more-members" />
      </div>
    </.mod_layout>
    """
  end

  defp member_row(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-3 rounded-lg border border-base-300">
      <div class="flex items-center gap-3 min-w-0">
        <.user_avatar user={@member.user} size={:sm} />
        <.link
          navigate={~p"/u/#{@member.user.nickname}"}
          class="font-medium truncate hover:underline"
        >
          {@member.user.nickname}
        </.link>
        <span
          :if={@member.user_id == @community.owner_id}
          class="badge badge-sm badge-primary"
        >
          Owner
        </span>
        <span
          :if={@member.role == "moderator" && @member.user_id != @community.owner_id}
          class="badge badge-sm badge-secondary"
        >
          Moderator
        </span>
      </div>
      <button
        :if={@member.user_id != @community.owner_id}
        phx-click="toggle-moderator"
        phx-value-user-id={@member.user_id}
        data-confirm={
          @member.role == "moderator" &&
            "Are you sure you want to remove #{@member.user.nickname} as a moderator?"
        }
        class={[
          "btn btn-xs rounded-full",
          if(@member.role == "moderator",
            do: "btn-outline btn-error",
            else: "btn-outline btn-primary"
          )
        ]}
      >
        {if @member.role == "moderator", do: "Remove Mod", else: "Make Mod"}
      </button>
    </div>
    """
  end
end
