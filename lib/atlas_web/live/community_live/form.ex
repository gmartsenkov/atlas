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
    params = maybe_generate_slug(params)

    changeset =
      Communities.change_community(%Communities.Community{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"community" => params}, socket) do
    params = maybe_generate_slug(params)

    case Communities.create_community(params) do
      {:ok, community} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community created!")
         |> push_navigate(to: ~p"/c/#{community.slug}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp maybe_generate_slug(%{"name" => name, "slug" => ""} = params) when name != "" do
    slug =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/\s+/, "-")
      |> String.trim("-")

    Map.put(params, "slug", slug)
  end

  defp maybe_generate_slug(params), do: params

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto">
      <div class="mb-8">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:text-base-content">
          &larr; Communities
        </.link>
      </div>

      <h1 class="text-3xl font-bold mb-8">New Community</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <.input field={@form[:name]} label="Name" placeholder="e.g. Triumph Motorcycles" />
        <.input field={@form[:slug]} label="Slug" placeholder="auto-generated from name" />
        <.input field={@form[:description]} type="textarea" label="Description" rows="3" />

        <div class="flex justify-end gap-3 pt-4">
          <.link navigate={~p"/"} class="btn">Cancel</.link>
          <button type="submit" class="btn btn-primary">Create Community</button>
        </div>
      </.form>
    </div>
    """
  end
end
