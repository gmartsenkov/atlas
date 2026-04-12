defmodule AtlasWeb.CommunityLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.{Authorization, Communities}

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        user = socket.assigns.current_scope.user

        if Authorization.can_edit_community?(user, community) do
          changeset = Communities.change_community_edit(community)
          moderators = Communities.list_community_moderators(community)

          {:ok,
           assign(socket,
             page_title: "Edit #{community.name}",
             community: community,
             form: to_form(changeset),
             icon_url: community.icon,
             moderators: moderators,
             member_search: "",
             member_results: []
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "Only the community owner can edit this community.")
           |> push_navigate(to: ~p"/c/#{name}")}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"community" => params}, socket) do
    changeset =
      Communities.change_community_edit(socket.assigns.community, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"community" => params}, socket) do
    params = Map.put(params, "icon", socket.assigns.icon_url)

    case Communities.update_community(socket.assigns.community, params) do
      {:ok, community} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community updated successfully.")
         |> push_navigate(to: ~p"/c/#{community.name}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("logo-uploaded", %{"url" => url}, socket) do
    {:noreply, assign(socket, icon_url: url)}
  end

  def handle_event("remove-logo", _params, socket) do
    {:noreply, assign(socket, icon_url: nil)}
  end

  def handle_event("search-members", %{"query" => query}, socket) do
    results = Communities.search_community_members(socket.assigns.community, query)
    {:noreply, assign(socket, member_search: query, member_results: results)}
  end

  def handle_event("toggle-moderator", %{"user-id" => user_id}, socket) do
    community = socket.assigns.community
    {user_id, ""} = Integer.parse(user_id)

    member =
      Enum.find(socket.assigns.member_results, &(&1.user_id == user_id)) ||
        Enum.find(socket.assigns.moderators, &(&1.user_id == user_id))

    if member && member.user_id != community.owner_id do
      new_role = if member.role == "moderator", do: "member", else: "moderator"
      {:ok, _} = Communities.set_member_role(community, user_id, new_role)
      moderators = Communities.list_community_moderators(community)

      results = refresh_search_results(community, socket.assigns.member_search)

      {:noreply, assign(socket, moderators: moderators, member_results: results)}
    else
      {:noreply, socket}
    end
  end

  defp refresh_search_results(community, search) do
    if String.trim(search) != "",
      do: Communities.search_community_members(community, search),
      else: []
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto">
      <.back_link navigate={~p"/c/#{@community.name}"}>{@community.name}</.back_link>

      <h1 class="text-3xl font-bold mb-8">Edit {@community.name}</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          rows="3"
          maxlength="2000"
        />

        <.logo_upload icon_url={@icon_url} />

        <.input
          field={@form[:suggestions_enabled]}
          type="checkbox"
          label="Allow community suggestions"
        />

        <.form_actions cancel_href={~p"/c/#{@community.name}"} submit_label="Save Changes" />
      </.form>

      <div class="mt-12">
        <h2 class="text-xl font-bold mb-4">Moderators</h2>

        <div :if={@moderators != []} class="space-y-2 mb-6">
          <.member_row
            :for={member <- @moderators}
            member={member}
            community={@community}
          />
        </div>
        <p :if={@moderators == []} class="text-sm text-base-content/50 mb-6">
          No moderators yet. Search for members below to add one.
        </p>

        <form phx-change="search-members" phx-submit="search-members">
          <input
            type="text"
            name="query"
            value={@member_search}
            placeholder="Search members by username..."
            phx-debounce="300"
            autocomplete="off"
            class="input input-bordered w-full rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          />
        </form>

        <div :if={@member_results != []} class="mt-3 space-y-2">
          <.member_row
            :for={member <- @member_results}
            member={member}
            community={@community}
          />
        </div>
        <p
          :if={String.trim(@member_search) != "" && @member_results == []}
          class="mt-3 text-sm text-base-content/50"
        >
          No members found.
        </p>
      </div>
    </div>
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
        {if @member.role == "moderator", do: "Remove Moderator", else: "Make Moderator"}
      </button>
    </div>
    """
  end

  defp logo_upload(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label">
        <span class="label-text">Icon</span>
      </label>
      <div
        id="logo-upload"
        phx-hook="LogoUpload"
        class="cursor-pointer border-2 border-dashed border-base-300 rounded-lg p-4 flex items-center gap-4 hover:border-primary/50 transition-colors"
      >
        <div :if={@icon_url} class="relative shrink-0">
          <div class="w-16 h-16 rounded-full bg-base-content/10 flex items-center justify-center overflow-hidden">
            <img src={@icon_url} alt="" class="w-12 h-12 object-contain" />
          </div>
          <button
            type="button"
            data-remove-logo
            phx-click="remove-logo"
            class="absolute -top-1 -right-1 btn btn-circle btn-xs btn-error"
          >
            <.icon name="hero-x-mark" class="w-3 h-3" />
          </button>
        </div>
        <div
          :if={!@icon_url}
          class="w-16 h-16 rounded-full bg-base-content/10 flex items-center justify-center shrink-0"
        >
          <.icon name="hero-photo" class="w-6 h-6 text-base-content/40" />
        </div>
        <div class="text-sm text-base-content/60">
          <p class="font-medium">Click to upload an icon</p>
          <p>PNG, JPG, SVG, or WebP. Max 1MB.</p>
        </div>
        <input type="file" accept="image/*" class="hidden" />
      </div>
    </div>
    """
  end
end
