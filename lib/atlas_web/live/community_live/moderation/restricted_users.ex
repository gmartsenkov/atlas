defmodule AtlasWeb.CommunityLive.Moderation.RestrictedUsers do
  @moduledoc false
  use AtlasWeb, :live_view

  alias Atlas.Accounts
  alias Atlas.Communities.Moderation.{RestrictUser, UnrestrictUser}
  alias Atlas.Communities.RestrictionsContext
  import AtlasWeb.CommunityLive.Moderation

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    community = socket.assigns.community
    page = RestrictionsContext.list_community_restrictions(community, limit: @per_page)

    {:ok,
     socket
     |> assign(
       page_title: "Restricted Users - #{community.name}",
       restrictions_page: page,
       show_restrict_modal: false,
       user_search: "",
       user_search_results: [],
       selected_user: nil,
       restrict_reason: ""
     )
     |> stream(:restrictions, page.items)}
  end

  @impl true
  def handle_event("load-more-restrictions", _params, socket) do
    %{restrictions_page: prev, community: community} = socket.assigns
    new_offset = prev.offset + prev.limit

    page =
      RestrictionsContext.list_community_restrictions(community,
        limit: @per_page,
        offset: new_offset
      )

    {:noreply,
     socket
     |> assign(restrictions_page: page)
     |> stream(:restrictions, page.items)}
  end

  def handle_event("open-restrict-modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_restrict_modal: true,
       user_search: "",
       user_search_results: [],
       selected_user: nil,
       restrict_reason: ""
     )}
  end

  def handle_event("close-restrict-modal", _params, socket) do
    {:noreply, assign(socket, show_restrict_modal: false)}
  end

  def handle_event("search-users", %{"value" => query}, socket) do
    results = Accounts.search_users_by_nickname(query)
    {:noreply, assign(socket, user_search: query, user_search_results: results)}
  end

  def handle_event("select-user", %{"id" => id}, socket) do
    {id, ""} = Integer.parse(id)
    user = Enum.find(socket.assigns.user_search_results, &(&1.id == id))

    {:noreply, assign(socket, selected_user: user, user_search: "", user_search_results: [])}
  end

  def handle_event("clear-selected-user", _params, socket) do
    {:noreply, assign(socket, selected_user: nil, user_search: "", user_search_results: [])}
  end

  def handle_event("save-restriction", %{"reason" => reason}, socket) do
    %{community: community, selected_user: user, current_scope: scope} = socket.assigns

    case RestrictUser.call(community, user, scope.user, %{reason: reason}) do
      {:ok, restriction} ->
        restriction = %{restriction | user: user, restricted_by: scope.user}

        {:noreply,
         socket
         |> stream_insert(:restrictions, restriction, at: 0)
         |> assign(
           show_restrict_modal: false,
           restrictions_page: %{
             socket.assigns.restrictions_page
             | total: socket.assigns.restrictions_page.total + 1
           }
         )
         |> put_flash(:info, "#{user.nickname} has been restricted.")}

      _ ->
        {:noreply,
         socket
         |> assign(show_restrict_modal: false)
         |> put_flash(:error, "Could not restrict user.")}
    end
  end

  def handle_event("unrestrict", %{"id" => id}, socket) do
    {id, ""} = Integer.parse(id)
    actor = socket.assigns.current_scope.user
    community = socket.assigns.community

    case UnrestrictUser.call(id, community, actor) do
      {:ok, restriction} ->
        {:noreply,
         socket
         |> stream_delete(:restrictions, restriction)
         |> assign(
           restrictions_page: %{
             socket.assigns.restrictions_page
             | total: socket.assigns.restrictions_page.total - 1
           }
         )
         |> put_flash(:info, "User has been unrestricted.")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Not authorized.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Restriction not found.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.mod_layout
      community={@community}
      live_action={:restricted}
      is_owner={@is_owner}
      pending_count={@pending_count}
      pending_reports_count={@pending_reports_count}
      moderated_communities={@moderated_communities}
    >
      <div class="max-w-3xl mx-auto">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-bold">Restricted Users</h1>
          <button phx-click="open-restrict-modal" class="btn btn-primary btn-sm rounded-full">
            <.icon name="hero-no-symbol" class="size-4" /> Restrict User
          </button>
        </div>

        <div
          :if={@restrictions_page.total == 0}
          class="text-base-content/50 py-8 text-center"
        >
          No restricted users.
        </div>

        <div :if={@restrictions_page.total > 0} class="overflow-x-auto">
          <table class="table">
            <thead>
              <tr>
                <th>User</th>
                <th>Reason</th>
                <th>Restricted by</th>
                <th>Date</th>
                <th></th>
              </tr>
            </thead>
            <tbody id="restrictions-list" phx-update="stream">
              <tr :for={{dom_id, restriction} <- @streams.restrictions} id={dom_id}>
                <td>
                  <div class="flex items-center gap-2">
                    <.user_avatar user={restriction.user} size={:sm} />
                    <.link
                      navigate={~p"/u/#{restriction.user.nickname}"}
                      class="font-medium hover:underline"
                    >
                      {restriction.user.nickname}
                    </.link>
                  </div>
                </td>
                <td class="text-base-content/60 max-w-xs truncate">
                  {restriction.reason || "-"}
                </td>
                <td>
                  <.link
                    navigate={~p"/u/#{restriction.restricted_by.nickname}"}
                    class="hover:underline"
                  >
                    {restriction.restricted_by.nickname}
                  </.link>
                </td>
                <td class="text-base-content/60 whitespace-nowrap">
                  {time_ago(restriction.inserted_at)}
                </td>
                <td>
                  <button
                    phx-click="unrestrict"
                    phx-value-id={restriction.id}
                    data-confirm={"Are you sure you want to unrestrict #{restriction.user.nickname}?"}
                    class="btn btn-xs btn-outline btn-error rounded-full"
                  >
                    Unrestrict
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <.load_more page={@restrictions_page} on_load_more="load-more-restrictions" />
      </div>
    </.mod_layout>

    <div
      :if={@show_restrict_modal}
      class="modal modal-open"
      id="restrict-modal"
    >
      <div class="modal-box rounded-2xl border border-base-300">
        <h3 class="text-lg font-bold mb-4">Restrict User</h3>

        <%= if @selected_user do %>
          <div class="flex items-center gap-3 p-3 rounded-lg border border-base-300 mb-4">
            <.user_avatar user={@selected_user} size={:sm} />
            <span class="font-medium flex-1">{@selected_user.nickname}</span>
            <button
              phx-click="clear-selected-user"
              class="btn btn-ghost btn-xs btn-circle"
              type="button"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>
          </div>

          <form phx-submit="save-restriction" id="restrict-form">
            <div class="form-control mb-4">
              <label class="label" for="restrict-reason">
                <span class="label-text font-medium">Reason (optional)</span>
              </label>
              <textarea
                id="restrict-reason"
                name="reason"
                rows="3"
                placeholder="Why is this user being restricted?"
                class="textarea textarea-bordered rounded-xl w-full"
              />
            </div>
            <div class="modal-action">
              <button
                type="button"
                class="btn rounded-full"
                phx-click="close-restrict-modal"
              >
                Cancel
              </button>
              <button type="submit" class="btn btn-error rounded-full">
                <.icon name="hero-no-symbol" class="size-4" /> Restrict
              </button>
            </div>
          </form>
        <% else %>
          <div class="form-control mb-4">
            <input
              type="text"
              value={@user_search}
              placeholder="Search users by nickname..."
              phx-keyup="search-users"
              phx-debounce="300"
              autocomplete="off"
              class="input input-bordered w-full rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
            />
          </div>

          <div :if={@user_search_results != []} class="space-y-1 max-h-60 overflow-y-auto">
            <button
              :for={user <- @user_search_results}
              phx-click="select-user"
              phx-value-id={user.id}
              class="flex items-center gap-3 p-2 rounded-lg hover:bg-base-200 w-full text-left transition"
              type="button"
            >
              <.user_avatar user={user} size={:sm} />
              <span class="font-medium">{user.nickname}</span>
            </button>
          </div>

          <div
            :if={@user_search != "" && @user_search_results == []}
            class="text-base-content/50 text-sm text-center py-4"
          >
            No users found.
          </div>

          <div class="modal-action">
            <button
              type="button"
              class="btn rounded-full"
              phx-click="close-restrict-modal"
            >
              Cancel
            </button>
          </div>
        <% end %>
      </div>
      <div class="modal-backdrop" phx-click="close-restrict-modal"></div>
    </div>
    """
  end
end
