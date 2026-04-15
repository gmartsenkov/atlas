defmodule AtlasWeb.CommunityLive.Moderation.General do
  @moduledoc false
  use AtlasWeb, :live_view

  alias Atlas.Authorization
  alias Atlas.Communities.CommunityManager
  import AtlasWeb.CommunityLive.Moderation

  @impl true
  def mount(_params, _session, socket) do
    community = socket.assigns.community
    user = socket.assigns.current_scope.user

    if Authorization.community_owner?(user, community) do
      changeset = CommunityManager.change_community_edit(community)

      {:ok,
       assign(socket,
         page_title: "Settings - #{community.name}",
         form: to_form(changeset),
         icon_url: community.icon
       )}
    else
      {:ok, push_navigate(socket, to: ~p"/mod/#{community.name}/proposals")}
    end
  end

  @impl true
  def handle_event("validate", %{"community" => params}, socket) do
    changeset =
      CommunityManager.change_community_edit(socket.assigns.community, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"community" => params}, socket) do
    params = Map.put(params, "icon", socket.assigns.icon_url)

    case CommunityManager.update_community(socket.assigns.community, params) do
      {:ok, community} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community updated successfully.")
         |> push_navigate(to: ~p"/mod/#{community.name}/settings")}

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

  @impl true
  def render(assigns) do
    ~H"""
    <.mod_layout
      community={@community}
      live_action={:settings}
      is_owner={@is_owner}
      pending_count={@pending_count}
      pending_reports_count={@pending_reports_count}
      moderated_communities={@moderated_communities}
    >
      <div class="max-w-xl mx-auto">
        <h1 class="text-2xl font-bold mb-6">General Settings</h1>

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
      </div>
    </.mod_layout>
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
