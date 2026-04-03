defmodule AtlasWeb.CommunityLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    community = Communities.get_community_by_name!(name)
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
      <div class="mb-8">
        <.link
          navigate={~p"/c/#{@community.name}"}
          class="text-sm text-base-content/60 hover:text-base-content"
        >
          &larr; {@community.name}
        </.link>
      </div>

      <h1 class="text-3xl font-bold mb-8">Edit {@community.name}</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
        <.input field={@form[:icon]} label="Icon URL" placeholder="https://example.com/icon.png" />
        <.input
          field={@form[:suggestions_enabled]}
          type="checkbox"
          label="Allow community suggestions"
        />

        <div class="flex justify-end gap-3 pt-4">
          <.link navigate={~p"/c/#{@community.name}"} class="btn rounded-full">Cancel</.link>
          <button type="submit" class="btn btn-primary rounded-full">Save Changes</button>
        </div>
      </.form>
    </div>
    """
  end
end
