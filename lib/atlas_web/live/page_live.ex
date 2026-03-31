defmodule AtlasWeb.PageLive do
  use AtlasWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Sample initial content to demonstrate the editor
    initial_content = [
      %{
        "id" => "heading-1",
        "type" => "heading",
        "props" => %{"level" => 1},
        "content" => [%{"type" => "text", "text" => "Triumph Trident 660"}],
        "children" => []
      },
      %{
        "id" => "para-1",
        "type" => "paragraph",
        "content" => [
          %{"type" => "text", "text" => "The Trident 660 is a "},
          %{
            "type" => "text",
            "text" => "triple-cylinder",
            "styles" => %{"bold" => true}
          },
          %{
            "type" => "text",
            "text" => " middleweight naked motorcycle produced by Triumph Motorcycles."
          }
        ],
        "children" => []
      },
      %{
        "id" => "heading-2",
        "type" => "heading",
        "props" => %{"level" => 2},
        "content" => [%{"type" => "text", "text" => "Specifications"}],
        "children" => []
      },
      %{
        "id" => "para-2",
        "type" => "paragraph",
        "content" => [
          %{"type" => "text", "text" => "Start editing to build out the knowledge base..."}
        ],
        "children" => []
      }
    ]

    {:ok,
     assign(socket,
       page_title: "Triumph Trident 660",
       content: initial_content,
       last_saved: nil,
       sections: extract_sections(initial_content)
     )}
  end

  @impl true
  def handle_event("editor-updated", %{"blocks" => blocks}, socket) do
    sections = extract_sections(blocks)
    {:noreply, assign(socket, content: blocks, sections: sections)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    # In a real app, this would persist to the database
    {:noreply, assign(socket, last_saved: DateTime.utc_now())}
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
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold">{@page_title}</h1>
          <p class="text-sm text-gray-500 mt-1">
            Community knowledge base page
          </p>
        </div>
        <div class="flex items-center gap-3">
          <span :if={@last_saved} class="text-sm text-green-600">
            Saved {Calendar.strftime(@last_saved, "%H:%M:%S")}
          </span>
          <button
            phx-click="save"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition"
          >
            Save Page
          </button>
        </div>
      </div>

      <div class="grid grid-cols-4 gap-6">
        <%!-- Sidebar: Table of contents derived from sections --%>
        <div class="col-span-1">
          <div class="sticky top-8 bg-gray-50 rounded-lg p-4">
            <h3 class="font-semibold text-sm text-gray-600 uppercase tracking-wide mb-3">
              Sections
            </h3>
            <ul class="space-y-2">
              <li :for={section <- @sections} class="text-sm text-gray-700 hover:text-blue-600">
                {section.title}
                <span class="text-gray-400 text-xs">({section.block_count} blocks)</span>
              </li>
            </ul>
          </div>
        </div>

        <%!-- Main editor area --%>
        <div class="col-span-3">
          <div class="bg-white rounded-lg border border-gray-200 min-h-[500px]">
            <div
              id="blocknote-editor"
              phx-hook="BlockEditor"
              phx-update="ignore"
              data-content={Jason.encode!(@content)}
            />
          </div>

          <%!-- Debug: show the raw JSON structure --%>
          <details class="mt-6">
            <summary class="text-sm text-gray-500 cursor-pointer hover:text-gray-700">
              View raw block JSON
            </summary>
            <pre class="mt-2 bg-gray-900 text-green-400 p-4 rounded-lg text-xs overflow-auto max-h-96"><code>{Jason.encode!(@content, pretty: true)}</code></pre>
          </details>
        </div>
      </div>
    </div>
    """
  end
end
