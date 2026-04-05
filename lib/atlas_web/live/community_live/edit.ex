defmodule AtlasWeb.CommunityLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        user = socket.assigns.current_scope.user

        if community.owner_id == user.id do
          changeset = Communities.change_community_edit(community)

          {:ok,
           assign(socket,
             page_title: "Edit #{community.name}",
             community: community,
             form: to_form(changeset)
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
        <.input
          field={@form[:icon]}
          label="Icon URL"
          placeholder="https://example.com/icon.png"
          maxlength="500"
        />
        <.input
          field={@form[:suggestions_enabled]}
          type="checkbox"
          label="Allow community suggestions"
        />

        <.form_actions cancel_href={~p"/c/#{@community.name}"} submit_label="Save Changes" />
      </.form>
    </div>
    """
  end
end
