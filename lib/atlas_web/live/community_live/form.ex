defmodule AtlasWeb.CommunityLive.Form do
  use AtlasWeb, :live_view

  alias Atlas.Communities.{Community, CommunityManager}
  alias Atlas.Communities.Community.Create

  @impl true
  def mount(_params, _session, socket) do
    changeset = CommunityManager.change_community()

    {:ok,
     assign(socket,
       page_title: "New Community",
       form: to_form(changeset),
       icon_url: nil
     )}
  end

  @impl true
  def handle_event("validate", %{"community" => params}, socket) do
    changeset =
      CommunityManager.change_community(%Community{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"community" => params}, socket) do
    params = Map.put(params, "icon", socket.assigns.icon_url)

    case Create.call(params, socket.assigns.current_scope.user) do
      {:ok, community} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community created!")
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto">
      <.back_link navigate={~p"/"}>Communities</.back_link>

      <h1 class="text-3xl font-bold mb-8">New Community</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <.input
          field={@form[:name]}
          label="Name"
          placeholder="e.g. Triumph_Motorcycles"
          maxlength="50"
        />
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

        <.form_actions cancel_href={~p"/"} submit_label="Create Community" />
      </.form>
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
