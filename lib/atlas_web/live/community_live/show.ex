defmodule AtlasWeb.CommunityLive.Show do
  use AtlasWeb, :live_view

  alias Atlas.Communities

  @impl true
  def mount(%{"community_slug" => slug}, _session, socket) do
    community = Communities.get_community_by_slug!(slug)
    current_user = current_user(socket)

    is_member =
      if current_user,
        do: Communities.member?(current_user, community),
        else: false

    {:ok,
     assign(socket,
       full_bleed: true,
       community: community,
       pages: community.pages,
       is_member: is_member
     )}
  end

  defp current_user(socket) do
    case socket.assigns do
      %{current_scope: %{user: %{id: _} = user}} -> user
      _ -> nil
    end
  end

  @impl true
  def handle_params(%{"page_slug" => page_slug}, _uri, socket) do
    page = Enum.find(socket.assigns.pages, fn p -> p.slug == page_slug end)

    if page do
      content = page.content || []

      {:noreply,
       assign(socket,
         page_title: "#{page.title} — #{socket.assigns.community.name}",
         current_page: page,
         content: content,
         sections: extract_sections(content)
       )}
    else
      {:noreply,
       push_navigate(socket, to: ~p"/c/#{socket.assigns.community.slug}")}
    end
  end

  def handle_params(_params, _uri, socket) do
    case socket.assigns.pages do
      [first | _] ->
        {:noreply,
         push_patch(socket, to: ~p"/c/#{socket.assigns.community.slug}/#{first.slug}", replace: true)}

      [] ->
        {:noreply,
         assign(socket,
           page_title: socket.assigns.community.name,
           current_page: nil,
           content: [],
           sections: []
         )}
    end
  end

  @impl true
  def handle_event("join", _params, socket) do
    user = current_user(socket)
    community = socket.assigns.community

    case Communities.join_community(user, community) do
      {:ok, _} -> {:noreply, assign(socket, is_member: true)}
      {:error, _} -> {:noreply, socket}
    end
  end

  def handle_event("leave", _params, socket) do
    user = current_user(socket)
    community = socket.assigns.community
    Communities.leave_community(user, community)
    {:noreply, assign(socket, is_member: false)}
  end

  # -- Helpers --

  defp extract_sections(blocks) do
    blocks
    |> Enum.filter(fn block ->
      block["type"] == "heading" && get_in(block, ["props", "level"]) in [1, 2, 3]
    end)
    |> Enum.map(fn block ->
      title = block |> get_in(["content", Access.at(0), "text"]) || "Untitled"
      level = get_in(block, ["props", "level"]) || 1
      %{title: title, level: level, id: block["id"]}
    end)
  end

  # -- Block rendering helpers --

  defp render_block(assigns) do
    ~H"""
    <%= case @block["type"] do %>
      <% "heading" -> %>
        <.render_heading block={@block} />
      <% "paragraph" -> %>
        <p class="mb-4 leading-relaxed"><.render_inline_content content={@block["content"]} /></p>
      <% "bulletListItem" -> %>
        <li class="ml-6 list-disc mb-1"><.render_inline_content content={@block["content"]} /></li>
      <% "numberedListItem" -> %>
        <li class="ml-6 list-decimal mb-1"><.render_inline_content content={@block["content"]} /></li>
      <% "checkListItem" -> %>
        <div class="flex items-start gap-2 mb-1">
          <input type="checkbox" checked={@block["props"]["checked"]} disabled class="mt-1" />
          <span><.render_inline_content content={@block["content"]} /></span>
        </div>
      <% _ -> %>
        <div class="mb-4"><.render_inline_content content={@block["content"]} /></div>
    <% end %>
    """
  end

  defp render_heading(assigns) do
    level = get_in(assigns.block, ["props", "level"]) || 1
    assigns = assign(assigns, :level, level)

    ~H"""
    <%= case @level do %>
      <% 1 -> %>
        <h1 id={@block["id"]} class="text-3xl font-bold mt-8 mb-4 scroll-mt-8">
          <.render_inline_content content={@block["content"]} />
        </h1>
      <% 2 -> %>
        <h2 id={@block["id"]} class="text-2xl font-semibold mt-6 mb-3 scroll-mt-8">
          <.render_inline_content content={@block["content"]} />
        </h2>
      <% 3 -> %>
        <h3 id={@block["id"]} class="text-xl font-semibold mt-4 mb-2 scroll-mt-8">
          <.render_inline_content content={@block["content"]} />
        </h3>
      <% _ -> %>
        <h4 id={@block["id"]} class="text-lg font-medium mt-4 mb-2 scroll-mt-8">
          <.render_inline_content content={@block["content"]} />
        </h4>
    <% end %>
    """
  end

  defp render_inline_content(assigns) do
    content = assigns.content || []
    assigns = assign(assigns, :items, content)

    ~H"""
    <%= for item <- @items do %>
      {render_inline_item(item)}
    <% end %>
    """
  end

  defp render_inline_item(%{"type" => "text", "text" => text, "styles" => styles})
       when map_size(styles) > 0 do
    text
    |> maybe_wrap("bold", styles, "<strong>", "</strong>")
    |> maybe_wrap("italic", styles, "<em>", "</em>")
    |> maybe_wrap("strikethrough", styles, "<s>", "</s>")
    |> maybe_wrap("code", styles, "<code class=\"bg-base-200 px-1 rounded text-sm\">", "</code>")
    |> Phoenix.HTML.raw()
  end

  defp render_inline_item(%{"type" => "text", "text" => text}), do: text

  defp render_inline_item(%{"type" => "link", "href" => href, "content" => content}) do
    text = Enum.map_join(content, "", fn item -> render_inline_item(item) end)
    {:safe, escaped_href} = Phoenix.HTML.html_escape(href)

    Phoenix.HTML.raw(
      "<a href=\"#{escaped_href}\" class=\"link link-primary\">#{text}</a>"
    )
  end

  defp render_inline_item(_), do: ""

  defp maybe_wrap(text, style_key, styles, open_tag, close_tag) do
    if styles[style_key] do
      "#{open_tag}#{text}#{close_tag}"
    else
      text
    end
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
          <div class="flex items-center gap-2.5 mt-2">
            <img
              :if={@community.icon}
              src={@community.icon}
              alt=""
              class="w-8 h-8 rounded-md object-cover shrink-0"
            />
            <div
              :if={!@community.icon}
              class="w-8 h-8 rounded-md bg-base-300 flex items-center justify-center shrink-0"
            >
              <.icon name="hero-rectangle-group" class="w-4 h-4 text-base-content/40" />
            </div>
            <h2 class="font-bold text-lg truncate">{@community.name}</h2>
          </div>
          <p :if={@community.description} class="text-xs text-base-content/50 mt-0.5 line-clamp-2">
            {@community.description}
          </p>
          <p :if={@community.owner} class="text-xs text-base-content/40 mt-1">
            Owned by {@community.owner.email}
          </p>
          <div :if={@current_scope && @current_scope.user} class="mt-2">
            <button
              :if={!@is_member}
              phx-click="join"
              class="btn btn-primary btn-xs w-full rounded-full"
            >
              Join Community
            </button>
            <button
              :if={@is_member}
              phx-click="leave"
              class="btn btn-ghost btn-xs w-full rounded-full"
            >
              Leave Community
            </button>
          </div>
        </div>

        <div class="px-5 pb-2">
          <h3 class="text-[11px] font-semibold text-base-content/40 uppercase tracking-wider">
            Pages
          </h3>
        </div>

        <nav id="sections-nav" phx-hook="ScrollTo" class="flex-1 overflow-y-auto px-3 pb-4">
          <div class="space-y-0.5">
            <%= for page <- @pages do %>
              <.link
                patch={~p"/c/#{@community.slug}/#{page.slug}"}
                class={[
                  "block px-3 py-2 rounded-md text-sm truncate transition",
                  if(@current_page && @current_page.id == page.id,
                    do: "bg-base-content/10 font-medium text-base-content",
                    else: "text-base-content/70 hover:bg-base-content/5 hover:text-base-content"
                  )
                ]}
              >
                {page.title}
              </.link>

              <%= if @current_page && @current_page.id == page.id && @sections != [] do %>
                <div class="ml-4 my-1.5 pl-3 border-l-2 border-base-content/10 space-y-0.5">
                  <a
                    :for={section <- @sections}
                    href={"##{section.id}"}
                    class={[
                      "block truncate transition rounded-sm hover:text-base-content",
                      if(section.level == 1,
                        do: "py-1.5 text-sm text-base-content/60",
                        else: ""
                      ),
                      if(section.level == 2,
                        do: "py-1 pl-2 text-sm text-base-content/50",
                        else: ""
                      ),
                      if(section.level == 3,
                        do: "py-1 pl-4 text-xs text-base-content/40",
                        else: ""
                      )
                    ]}
                  >
                    {section.title}
                  </a>
                </div>
              <% end %>
            <% end %>
          </div>
        </nav>

        <div class="px-4 py-3 border-t border-base-300/60">
          <.link
            navigate={~p"/c/#{@community.slug}/new"}
            class="btn btn-primary btn-sm w-full"
          >
            New Page
          </.link>
        </div>
      </aside>

      <%!-- Main content --%>
      <main class="flex-1 overflow-y-auto">
        <div :if={@current_page} class="max-w-3xl mx-auto py-8 px-8">
          <div class="flex items-center justify-between mb-8">
            <h1 class="text-3xl font-bold">{@current_page.title}</h1>
            <.link
              navigate={~p"/c/#{@community.slug}/#{@current_page.slug}/edit"}
              class="btn btn-primary btn-sm"
            >
              Edit
            </.link>
          </div>

          <div class="prose max-w-none">
            <.render_block :for={block <- @content} block={block} />
          </div>
        </div>

        <div :if={!@current_page} class="flex items-center justify-center h-full text-base-content/40">
          <div class="text-center">
            <p class="text-lg mb-4">No pages yet.</p>
            <.link
              navigate={~p"/c/#{@community.slug}/new"}
              class="btn btn-primary btn-sm"
            >
              Create the first page
            </.link>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
