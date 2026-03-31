defmodule AtlasWeb.PageLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_slug" => community_slug, "page_slug" => page_slug}, _session, socket) do
    page = Communities.get_page_by_slugs!(community_slug, page_slug)

    {:ok,
     assign(socket,
       page_title: "Edit #{page.title}",
       page: page,
       community: page.community,
       content: page.content || [],
       last_saved: nil,
       sections: extract_sections(page.content || [])
     )}
  end

  @impl true
  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    sections = extract_sections(blocks)
    {:noreply, assign(socket, content: blocks, sections: sections)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    case Communities.update_page(socket.assigns.page, %{content: socket.assigns.content}) do
      {:ok, page} ->
        {:noreply, assign(socket, page: page, last_saved: DateTime.utc_now())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save page")}
    end
  end

  defp extract_sections(blocks) do
    blocks
    |> Enum.chunk_by(fn block ->
      block["type"] == "heading" && get_in(block, ["props", "level"]) in [1, 2]
    end)
    |> Enum.chunk_every(2)
    |> Enum.map(fn
      [heading_group, content_group] ->
        heading = List.first(heading_group)
        title = heading |> get_in(["content", Access.at(0), "text"]) || "Untitled"
        %{title: title, block_count: length(content_group)}

      [group] ->
        heading = Enum.find(group, fn b -> b["type"] == "heading" end)

        if heading do
          title = heading |> get_in(["content", Access.at(0), "text"]) || "Untitled"
          %{title: title, block_count: 0}
        else
          %{title: "Introduction", block_count: length(group)}
        end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-5xl mx-auto py-8 px-4">
      <div class="mb-6">
        <.link
          navigate={~p"/c/#{@community.slug}"}
          class="text-sm text-base-content/60 hover:text-base-content"
        >
          &larr; {@community.name}
        </.link>
      </div>

      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold">{@page_title}</h1>
          <p class="text-sm text-base-content/60 mt-1">
            Community knowledge base page
          </p>
        </div>
        <div class="flex items-center gap-3">
          <.link
            navigate={~p"/c/#{@community.slug}/#{@page.slug}"}
            class="btn"
          >
            Cancel
          </.link>
          <span :if={@last_saved} class="text-sm text-success">
            Saved {Calendar.strftime(@last_saved, "%H:%M:%S")}
          </span>
          <button phx-click="save" class="btn btn-primary">
            Save Page
          </button>
        </div>
      </div>

      <div class="grid grid-cols-4 gap-6">
        <div class="col-span-1">
          <div class="sticky top-8 bg-base-200 rounded-lg p-4">
            <h3 class="font-semibold text-sm text-base-content/60 uppercase tracking-wide mb-3">
              Sections
            </h3>
            <ul class="space-y-2">
              <li :for={section <- @sections} class="text-sm text-base-content/80">
                {section.title}
                <span class="text-base-content/40 text-xs">({section.block_count} blocks)</span>
              </li>
            </ul>
          </div>
        </div>

        <div class="col-span-3">
          <div class="bg-base-100 rounded-lg border border-base-300 min-h-[500px]">
            <div
              id="blocknote-editor"
              phx-hook="BlockEditor"
              phx-update="ignore"
              data-content={Jason.encode!(@content)}
            />
          </div>

          <details class="mt-6">
            <summary class="text-sm text-base-content/40 cursor-pointer hover:text-base-content/60">
              View raw block JSON
            </summary>
            <pre class="mt-2 bg-neutral text-neutral-content p-4 rounded-lg text-xs overflow-auto max-h-96"><code>{Jason.encode!(@content, pretty: true)}</code></pre>
          </details>
        </div>
      </div>
    </div>
    """
  end
end
