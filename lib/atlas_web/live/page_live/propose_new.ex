defmodule AtlasWeb.PageLive.ProposeNew do
  use AtlasWeb, :live_view

  alias Atlas.{Authorization, Communities}

  @impl true
  def mount(%{"community_name" => community_name}, _session, socket) do
    case Communities.get_community_by_name(community_name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        if Authorization.can_propose?(community) do
          collections = Communities.list_collections(community)

          {:ok,
           assign(socket,
             page_title: "Propose New Page — #{community.name}",
             community: community,
             collections: collections,
             title: "",
             slug: "",
             collection_id: nil,
             proposed_content: []
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "Suggestions are disabled for this community.")
           |> push_navigate(to: ~p"/c/#{community.name}")}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"value" => title}, socket) do
    slug = slugify(title)
    {:noreply, assign(socket, title: title, slug: slug)}
  end

  def handle_event("validate", %{"collection_id" => collection_id}, socket) do
    {:noreply, assign(socket, collection_id: parse_collection_id(collection_id))}
  end

  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    {:noreply, assign(socket, proposed_content: blocks)}
  end

  def handle_event("submit-proposal", _params, socket) do
    user = socket.assigns.current_scope.user
    community = socket.assigns.community

    attrs = %{
      proposed_title: socket.assigns.title,
      proposed_slug: socket.assigns.slug,
      proposed_content: socket.assigns.proposed_content,
      collection_id: socket.assigns.collection_id
    }

    case Communities.create_page_proposal(community, user, attrs) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, "New page proposal submitted!")
         |> push_navigate(to: ~p"/c/#{community.name}")}

      {:error, changeset} ->
        errors =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
          |> Enum.map_join(", ", fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)

        {:noreply, put_flash(socket, :error, "Failed to submit: #{errors}")}
    end
  end

  defp slugify(title), do: Communities.slugify(title)

  defp parse_collection_id(""), do: nil
  defp parse_collection_id(nil), do: nil

  defp parse_collection_id(id) do
    case Integer.parse(id) do
      {int, _} -> int
      :error -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- Sticky top bar --%>
    <div class="sticky top-0 z-10 border-b border-base-300 bg-base-100/95 backdrop-blur-sm">
      <div class="max-w-3xl mx-auto px-8 flex items-center justify-between h-14">
        <div class="flex items-center gap-3 min-w-0">
          <.link
            navigate={~p"/c/#{@community.name}"}
            class="text-base-content/40 hover:text-base-content transition shrink-0"
          >
            <.icon name="hero-arrow-left" class="size-4" />
          </.link>
          <div class="min-w-0">
            <h1 class="font-bold text-sm truncate">Propose New Page</h1>
            <p class="text-xs text-base-content/50 truncate">{@community.name}</p>
          </div>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <.link
            navigate={~p"/c/#{@community.name}"}
            class="btn btn-ghost btn-sm rounded-full"
          >
            Cancel
          </.link>
          <button
            phx-click="submit-proposal"
            phx-disable-with="Submitting..."
            disabled={@title == "" || @slug == ""}
            class="btn btn-primary btn-sm rounded-full"
          >
            Submit Proposal
          </button>
        </div>
      </div>
    </div>

    <div class="max-w-3xl mx-auto py-8 px-8">
      <%!-- Metadata form --%>
      <div class="border border-base-300 rounded-xl p-6 mb-8 bg-base-200/30">
        <.section_label class="mb-4">Page Details</.section_label>

        <div class="space-y-4">
          <div class="fieldset">
            <label>
              <span class="label mb-1">Title</span>
              <input
                type="text"
                value={@title}
                phx-keyup="validate"
                phx-debounce="300"
                maxlength="255"
                name="title"
                placeholder="Page title"
                class="w-full input rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
                autocomplete="off"
              />
            </label>
          </div>

          <div class="fieldset">
            <label>
              <span class="label mb-1">Slug</span>
              <input
                type="text"
                value={@slug}
                readonly
                class="w-full input rounded-full bg-base-200 text-base-content/60"
              />
            </label>
          </div>

          <div :if={@collections != []} class="fieldset">
            <label>
              <span class="label mb-1">Collection (optional)</span>
              <select
                name="collection_id"
                phx-change="validate"
                class="w-full select rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
              >
                <option value="">None</option>
                <option
                  :for={collection <- @collections}
                  value={collection.id}
                  selected={@collection_id == collection.id}
                >
                  {collection.name}
                </option>
              </select>
            </label>
          </div>
        </div>
      </div>

      <%!-- BlockNote editor --%>
      <.section_label class="mb-4">Page Content</.section_label>
      <div class="prose max-w-none">
        <div
          id="blocknote-editor-propose-new"
          class="min-h-[300px] flex flex-col"
          phx-hook="BlockEditor"
          phx-update="ignore"
          data-content={Jason.encode!([])}
        />
      </div>
    </div>
    """
  end
end
