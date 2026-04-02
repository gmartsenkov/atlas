defmodule AtlasWeb.BlockRenderer do
  use Phoenix.Component

  def render_block(assigns) do
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

  def render_heading(assigns) do
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

  def render_inline_content(assigns) do
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

    Phoenix.HTML.raw("<a href=\"#{escaped_href}\" class=\"link link-primary\">#{text}</a>")
  end

  defp render_inline_item(_), do: ""

  defp maybe_wrap(text, style_key, styles, open_tag, close_tag) do
    if styles[style_key] do
      "#{open_tag}#{text}#{close_tag}"
    else
      text
    end
  end
end
