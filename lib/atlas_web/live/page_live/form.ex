defmodule AtlasWeb.PageLive.Form do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_name" => community_name}, _session, socket) do
    case Communities.get_community_by_name(community_name) do
      {:error, :not_found} ->
        {:ok, redirect(socket, to: ~p"/404")}

      {:ok, community} ->
        changeset = Communities.change_page(%Communities.Page{}, %{community_id: community.id})

        {:ok,
         assign(socket,
           page_title: "New Page",
           community: community,
           form: to_form(changeset)
         )}
    end
  end

  @impl true
  def handle_event("validate", %{"page" => params}, socket) do
    params = generate_slug(params)

    changeset =
      Communities.change_page(
        %Communities.Page{community_id: socket.assigns.community.id},
        Map.put(params, "community_id", socket.assigns.community.id)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"page" => params}, socket) do
    community = socket.assigns.community
    params = generate_slug(params)
    params = Map.put(params, "community_id", community.id)

    case Communities.create_page(params, socket.assigns.current_scope.user) do
      {:ok, page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page created!")
         |> push_navigate(to: ~p"/c/#{community.name}/#{page.slug}/edit")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp generate_slug(%{"title" => title} = params) when is_binary(title) do
    slug =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.trim()
      |> String.replace(~r/\s+/, "-")
      |> String.trim("-")

    Map.put(params, "slug", slug)
  end

  defp generate_slug(params), do: params

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto">
      <.back_link navigate={~p"/c/#{@community.name}"}>{@community.name}</.back_link>

      <h1 class="text-3xl font-bold mb-8">New Page</h1>

      <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
        <.input field={@form[:title]} label="Title" placeholder="e.g. Getting Started" />
        <.input
          field={@form[:slug]}
          label="Slug"
          readonly
          errors={@form[:slug].errors |> Enum.map(&translate_error/1)}
          class="w-full input text-lg text-base-content cursor-not-allowed bg-base-200"
        />

        <.form_actions cancel_href={~p"/c/#{@community.name}"} submit_label="Create Page" />
      </.form>
    </div>
    """
  end
end
