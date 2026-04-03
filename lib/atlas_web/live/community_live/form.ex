defmodule AtlasWeb.CommunityLive.Form do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(_params, _session, socket) do
    changeset = Communities.change_community()

    {:ok,
     assign(socket,
       page_title: "New Community",
       form: to_form(changeset)
     )}
  end

  @impl true
  def handle_event("validate", %{"community" => params}, socket) do
    changeset =
      Communities.change_community(%Communities.Community{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"community" => params}, socket) do
    case Communities.create_community(params, socket.assigns.current_scope.user) do
      {:ok, community} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community created!")
         |> push_navigate(to: ~p"/c/#{community.name}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto">
      <.back_link navigate={~p"/"}>Communities</.back_link>

      <h1 class="text-3xl font-bold mb-8">New Community</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <.input field={@form[:name]} label="Name" placeholder="e.g. Triumph_Motorcycles" />
        <.input field={@form[:description]} type="textarea" label="Description" rows="3" />
        <.input field={@form[:icon]} label="Icon URL" placeholder="https://example.com/icon.png" />
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
end
