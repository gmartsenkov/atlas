defmodule AtlasWeb.PageLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_slug" => community_slug, "page_slug" => page_slug}, _session, socket) do
    community = Communities.get_community_by_slug!(community_slug)
    page = Communities.get_page_by_slugs!(community_slug, page_slug)
    content = page.content || []

    {:ok,
     assign(socket,
       full_bleed: true,
       page_title: "Edit #{page.title}",
       page: page,
       community: community,
       pages: community.pages,
       content: content,
       last_saved: nil,
       sections: extract_sections(content)
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
    |> Enum.filter(fn block ->
      block["type"] == "heading" && get_in(block, ["props", "level"]) in [1, 2, 3]
    end)
    |> Enum.map(fn block ->
      title = block |> get_in(["content", Access.at(0), "text"]) || "Untitled"
      level = get_in(block, ["props", "level"]) || 1
      %{title: title, level: level}
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)]">
      <%!-- Sidebar --%>
      <aside class="w-72 shrink-0 border-r border-base-300 flex flex-col bg-base-200/30">
        <div class="px-5 pt-5 pb-4">
          <.link navigate={~p"/"} class="text-xs text-base-content/40 hover:text-base-content transition">
            &larr; Communities
          </.link>
          <h2 class="font-bold text-lg mt-2 truncate">{@community.name}</h2>
        </div>

        <div class="px-5 pb-2">
          <h3 class="text-[11px] font-semibold text-base-content/40 uppercase tracking-wider">
            Pages
          </h3>
        </div>

        <nav class="flex-1 overflow-y-auto px-3 pb-4">
          <div class="space-y-0.5">
            <%= for page <- @pages do %>
              <.link
                navigate={~p"/c/#{@community.slug}/#{page.slug}"}
                class={[
                  "block px-3 py-2 rounded-md text-sm truncate transition",
                  if(page.id == @page.id,
                    do: "bg-base-content/10 font-medium text-base-content",
                    else: "text-base-content/70 hover:bg-base-content/5 hover:text-base-content"
                  )
                ]}
              >
                {page.title}
              </.link>

              <%= if page.id == @page.id && @sections != [] do %>
                <div class="ml-4 my-1.5 pl-3 border-l-2 border-base-content/10 space-y-0.5">
                  <span
                    :for={section <- @sections}
                    class={[
                      "block truncate text-base-content/50",
                      if(section.level == 1, do: "py-1.5 text-sm", else: ""),
                      if(section.level == 2, do: "py-1 pl-2 text-sm", else: ""),
                      if(section.level == 3, do: "py-1 pl-4 text-xs", else: "")
                    ]}
                  >
                    {section.title}
                  </span>
                </div>
              <% end %>
            <% end %>
          </div>
        </nav>
      </aside>

      <%!-- Main content --%>
      <main class="flex-1 overflow-y-auto flex flex-col">
        <div class="flex items-center justify-between px-8 py-4 border-b border-base-300">
          <div class="flex items-center gap-3">
            <h1 class="text-xl font-bold">{@page.title}</h1>
            <span class="text-xs text-base-content/40 uppercase tracking-wide">Editing</span>
          </div>
          <div class="flex items-center gap-3">
            <span :if={@last_saved} class="text-sm text-success">
              Saved {Calendar.strftime(@last_saved, "%H:%M:%S")}
            </span>
            <.link
              navigate={~p"/c/#{@community.slug}/#{@page.slug}"}
              class="btn btn-ghost btn-sm"
            >
              Cancel
            </.link>
            <button phx-click="save" class="btn btn-primary btn-sm">
              Save
            </button>
          </div>
        </div>

        <div class="flex-1 flex flex-col">
          <div class="max-w-3xl mx-auto py-6 px-8 w-full flex-1 flex flex-col">
            <div class="bg-base-100 rounded-lg border border-base-300 flex-1 flex flex-col">
              <div
                id="blocknote-editor"
                class="flex-1 flex flex-col"
                phx-hook="BlockEditor"
                phx-update="ignore"
                data-content={Jason.encode!(@content)}
              />
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
