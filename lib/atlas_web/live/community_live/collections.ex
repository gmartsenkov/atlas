defmodule AtlasWeb.CommunityLive.Collections do
  use AtlasWeb, :live_view

  alias Atlas.{Authorization, Communities}

  @impl true
  def mount(%{"community_name" => name}, _session, socket) do
    case Communities.get_community_by_name(name) do
      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError

      {:ok, community} ->
        user = socket.assigns.current_scope.user

        is_moderator = Communities.moderator?(user, community)

        if Authorization.can_manage_collections?(user, community, is_moderator) do
          {:ok,
           assign(socket,
             page_title: "Collections — #{community.name}",
             community: community,
             collections: community.collections,
             pages: community.pages,
             new_collection_name: ""
           )}
        else
          {:ok,
           socket
           |> put_flash(:error, "You don't have permission to manage collections.")
           |> push_navigate(to: ~p"/c/#{name}")}
        end
    end
  end

  @impl true
  def handle_event("create-collection", %{"name" => name}, socket) do
    name = String.trim(name)

    if name != "" do
      case Communities.create_collection(socket.assigns.community, %{"name" => name}) do
        {:ok, _collection} ->
          {:noreply,
           socket
           |> assign(new_collection_name: "")
           |> refresh_data()}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Collection name already exists.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete-collection", %{"id" => id}, socket) do
    with {:ok, collection} <- Communities.get_collection(id),
         true <- collection.community_id == socket.assigns.community.id do
      {:ok, _} = Communities.delete_collection(collection)

      {:noreply,
       socket
       |> put_flash(:info, "Collection deleted. Pages have been ungrouped.")
       |> refresh_data()}
    else
      _ -> {:noreply, put_flash(socket, :error, "Collection not found.")}
    end
  end

  def handle_event("reorder-collections", %{"ids" => ids}, socket) do
    ids = safe_parse_ids(ids)

    case Communities.reorder_collections(socket.assigns.community, ids) do
      :ok -> {:noreply, refresh_data(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to reorder collections.")}
    end
  end

  def handle_event("reorder-pages", %{"ids" => ids}, socket) do
    ids = safe_parse_ids(ids)

    case Communities.reorder_pages(socket.assigns.community, ids) do
      :ok -> {:noreply, socket}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to reorder pages.")}
    end
  end

  def handle_event(
        "move-page",
        %{"page-id" => page_id, "collection-id" => col_id} = params,
        socket
      ) do
    page_id_int = safe_parse_int(page_id)
    page = Enum.find(socket.assigns.pages, &(&1.id == page_id_int))

    if page do
      col_id_int = if col_id == "", do: nil, else: safe_parse_int(col_id)
      persist_page_move(page, col_id_int, params, socket.assigns.community)
      pages = update_pages_in_memory(socket.assigns.pages, page.id, col_id_int, params)
      {:noreply, assign(socket, pages: pages)}
    else
      {:noreply, socket}
    end
  end

  defp persist_page_move(page, nil, params, community) do
    Communities.remove_page_from_collection(page)
    persist_page_order(params, community)
  end

  defp persist_page_move(page, col_id_int, params, community) do
    Communities.assign_page_to_collection(page, col_id_int)
    persist_page_order(params, community)
  end

  defp persist_page_order(%{"ids" => ids}, community) when is_list(ids) do
    Communities.reorder_pages(community, safe_parse_ids(ids))
  end

  defp persist_page_order(_, _community), do: :ok

  defp update_pages_in_memory(pages, moved_id, col_id_int, params) do
    order_map = build_order_map(params)

    Enum.map(pages, fn p ->
      p = if p.id == moved_id, do: %{p | collection_id: col_id_int}, else: p
      Map.get(order_map, p.id, p.sort_order) |> then(&%{p | sort_order: &1})
    end)
  end

  defp build_order_map(%{"ids" => ids}) when is_list(ids) do
    ids
    |> Enum.with_index()
    |> Map.new(fn {id, idx} -> {safe_parse_int(id), idx} end)
  end

  defp build_order_map(_), do: %{}

  defp safe_parse_ids(ids) when is_list(ids) do
    Enum.map(ids, &safe_parse_int/1)
  end

  defp safe_parse_int(val) when is_integer(val), do: val

  defp safe_parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {n, ""} -> n
      _ -> 0
    end
  end

  defp refresh_data(socket) do
    case Communities.get_community_by_name(socket.assigns.community.name) do
      {:ok, community} ->
        assign(socket,
          community: community,
          collections: community.collections,
          pages: community.pages
        )

      {:error, :not_found} ->
        push_navigate(socket, to: ~p"/")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <.back_link navigate={~p"/c/#{@community.name}"}>{@community.name}</.back_link>

      <h1 class="text-3xl font-bold mb-8">Collections</h1>

      <%!-- Create new collection --%>
      <form phx-submit="create-collection" class="flex gap-2 mb-8">
        <input
          type="text"
          name="name"
          value={@new_collection_name}
          maxlength="100"
          placeholder="New collection name..."
          class="input input-bordered flex-1 rounded-full focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary"
          autocomplete="off"
        />
        <button type="submit" phx-disable-with="Creating..." class="btn btn-primary rounded-full">
          <.icon name="hero-plus" class="size-4" /> Create
        </button>
      </form>

      <%!-- Collections list --%>
      <div :if={@collections == []} class="text-sm text-base-content/50 mb-8">
        No collections yet. Create one above to start organizing pages.
      </div>

      <div
        id="collections-sortable"
        phx-hook="SortableHook"
        data-sortable-event="reorder-collections"
        class="space-y-6"
      >
        <%= for collection <- @collections do %>
          <div id={"collection-#{collection.id}"} data-sortable-id={collection.id}>
            <div class="border border-base-300 rounded-xl p-4">
              <div class="flex items-center justify-between mb-3">
                <h2 class="font-semibold flex items-center gap-2">
                  <span
                    data-drag-handle
                    class="cursor-grab active:cursor-grabbing text-base-content/30 hover:text-base-content/60"
                  >
                    <.icon name="hero-bars-2" class="size-4" />
                  </span>
                  <.icon name="hero-folder" class="size-4 text-base-content/40" />
                  {collection.name}
                </h2>
                <button
                  phx-click="delete-collection"
                  phx-value-id={collection.id}
                  data-confirm={"Delete \"#{collection.name}\"? Pages will be ungrouped, not deleted."}
                  class="btn btn-ghost btn-xs text-error/60 hover:text-error rounded-full"
                >
                  <.icon name="hero-trash" class="size-3.5" /> Delete
                </button>
              </div>

              <div
                id={"collection-pages-#{collection.id}"}
                phx-hook="PageDragHook"
                data-collection-id={collection.id}
                class="space-y-1 min-h-[2rem]"
              >
                <%= for page <- collection_pages(@pages, collection.id) do %>
                  <div
                    id={"page-item-#{page.id}"}
                    data-page-id={page.id}
                    class="flex items-center gap-2 py-1.5 px-2 rounded-lg hover:bg-base-200/50 cursor-grab active:cursor-grabbing"
                  >
                    <.icon name="hero-document" class="size-3.5 text-base-content/40 shrink-0" />
                    <span class="text-sm truncate">{page.title}</span>
                  </div>
                <% end %>
                <div
                  :if={collection_pages(@pages, collection.id) == []}
                  class="text-xs text-base-content/40 py-2 text-center"
                >
                  Empty — drag pages here
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- Unassigned pages (always visible as drop zone) --%>
      <div class="mt-8">
        <h2 class="font-semibold text-base-content/60 mb-3">Unassigned Pages</h2>
        <div
          id="unassigned-pages"
          phx-hook="PageDragHook"
          data-collection-id=""
          class="space-y-1 min-h-[2.5rem] border-2 border-dashed border-base-300 rounded-xl p-3"
        >
          <%= for page <- unassigned_pages(@pages) do %>
            <div
              id={"page-item-#{page.id}"}
              data-page-id={page.id}
              class="flex items-center gap-2 py-2 px-3 rounded-lg border border-base-300 bg-base-100 cursor-grab active:cursor-grabbing"
            >
              <.icon name="hero-document" class="size-3.5 text-base-content/40 shrink-0" />
              <span class="text-sm truncate">{page.title}</span>
            </div>
          <% end %>
          <div
            :if={unassigned_pages(@pages) == []}
            class="text-xs text-base-content/40 py-1 text-center"
          >
            Drag pages here to unassign them.
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp collection_pages(pages, collection_id) do
    pages
    |> Enum.filter(&(&1.collection_id == collection_id))
    |> Enum.sort_by(&{&1.sort_order, &1.title})
  end

  defp unassigned_pages(pages) do
    pages
    |> Enum.filter(&is_nil(&1.collection_id))
    |> Enum.sort_by(&{&1.sort_order, &1.title})
  end
end
