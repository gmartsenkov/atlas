defmodule AtlasWeb.PageLive.Edit do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_name" => community_name, "page_slug" => page_slug}, _session, socket) do
    user = socket.assigns.current_scope.user

    with {:ok, community} <- Communities.get_community_by_name(community_name),
         {:ok, page} <- Communities.get_page_by_slugs(community_name, page_slug),
         true <- page.owner_id == user.id || community.owner_id == user.id do
      content = Communities.merge_sections_content(page.sections)
      headings = Communities.extract_headings(page.sections)

      {:ok,
       assign(socket,
         full_bleed: true,
         page_title: "Edit #{page.title}",
         page: page,
         community: community,
         headings: headings,
         content: content,
         last_saved: nil
       )}
    else
      false ->
        {:ok,
         socket
         |> put_flash(:error, "You don't have permission to edit this page.")
         |> push_navigate(to: ~p"/c/#{community_name}")}

      {:error, :not_found} ->
        raise AtlasWeb.NotFoundError
    end
  end

  @impl true
  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    {:noreply, assign(socket, content: blocks)}
  end

  def handle_event("scroll-to-section", %{"id" => id}, socket) do
    {:noreply, push_event(socket, "editor-scroll-to", %{id: id})}
  end

  def handle_event("save", _params, socket) do
    case Communities.save_page_content(socket.assigns.page, socket.assigns.content) do
      {:ok, sections} ->
        headings = Communities.extract_headings(sections)
        {:noreply, assign(socket, last_saved: DateTime.utc_now(), headings: headings)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to save")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-4rem)]">
      <%!-- Sidebar --%>
      <aside class="w-72 shrink-0 border-r border-base-300 flex flex-col bg-base-200/30">
        <div class="px-5 pt-5 pb-4">
          <.link
            navigate={~p"/c/#{@community.name}/#{@page.slug}"}
            class="text-xs text-base-content/40 hover:text-base-content transition"
          >
            &larr; {@page.title}
          </.link>
          <h2 class="font-bold text-lg mt-2 truncate">Editing</h2>
        </div>

        <div class="px-5 pb-2">
          <.section_label>Sections</.section_label>
        </div>

        <nav class="flex-1 overflow-y-auto px-3 pb-4">
          <div class="space-y-0.5">
            <%= for heading <- @headings do %>
              <button
                phx-click="scroll-to-section"
                phx-value-id={heading.id}
                class={[
                  "block w-full text-left px-3 py-1.5 rounded-md text-sm truncate text-base-content/50 hover:text-base-content hover:bg-base-content/5 transition cursor-pointer",
                  heading.level > 2 && "ml-3"
                ]}
              >
                {heading.text}
              </button>
            <% end %>
            <div :if={@headings == []} class="px-3 text-sm text-base-content/40">
              No sections yet.
            </div>
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
              navigate={~p"/c/#{@community.name}/#{@page.slug}"}
              class="btn btn-ghost btn-sm rounded-full"
            >
              Cancel
            </.link>
            <button phx-click="save" class="btn btn-primary btn-sm rounded-full">
              Save
            </button>
          </div>
        </div>

        <div id="editor-scroll" phx-hook="EditorScroll" class="flex-1 overflow-y-auto">
          <div class="max-w-3xl mx-auto py-6 px-8 w-full">
            <div
              id="blocknote-editor"
              class="min-h-[400px] flex flex-col"
              phx-hook="BlockEditor"
              phx-update="ignore"
              data-content={Jason.encode!(@content)}
            />
          </div>
        </div>
      </main>
    </div>
    """
  end
end
