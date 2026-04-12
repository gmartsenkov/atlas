defmodule AtlasWeb.BlockRenderer do
  @moduledoc false
  use Phoenix.Component

  attr :block, :map, required: true
  attr :highlight, :string, default: nil

  def render_block(assigns) do
    ~H"""
    <%= case @block["type"] do %>
      <% "heading" -> %>
        <.render_heading block={@block} highlight={@highlight} />
      <% "paragraph" -> %>
        <p class="mb-4 leading-relaxed">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </p>
      <% "bulletListItem" -> %>
        <li class="ml-6 list-disc mb-1">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </li>
      <% "numberedListItem" -> %>
        <li class="ml-6 list-decimal mb-1">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </li>
      <% "checkListItem" -> %>
        <div class="flex items-start gap-2 mb-1">
          <input type="checkbox" checked={get_in(@block, ["props", "checked"])} disabled class="mt-1" />
          <span><.render_inline_content content={@block["content"]} highlight={@highlight} /></span>
        </div>
      <% "image" -> %>
        <.render_image block={@block} />
      <% "youtube" -> %>
        <.render_youtube block={@block} />
      <% _ -> %>
        <div class="mb-4">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </div>
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
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </h1>
      <% 2 -> %>
        <h2 id={@block["id"]} class="text-2xl font-semibold mt-6 mb-3 scroll-mt-8">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </h2>
      <% 3 -> %>
        <h3 id={@block["id"]} class="text-xl font-semibold mt-4 mb-2 scroll-mt-8">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </h3>
      <% _ -> %>
        <h4 id={@block["id"]} class="text-lg font-medium mt-4 mb-2 scroll-mt-8">
          <.render_inline_content content={@block["content"]} highlight={@highlight} />
        </h4>
    <% end %>
    """
  end

  defp render_image(assigns) do
    props = assigns.block["props"] || %{}
    url = props["url"] || ""
    url = if safe_url?(url), do: url, else: ""
    caption = props["caption"] || ""
    width = if is_number(props["previewWidth"]), do: props["previewWidth"], else: nil
    assigns = assign(assigns, url: url, caption: caption, width: width)

    ~H"""
    <figure class="mb-4">
      <img
        src={@url}
        alt={if(@caption != "", do: @caption, else: "Embedded image")}
        style={@width && "width: #{@width}px"}
        class="max-w-full rounded"
      />
      <figcaption :if={@caption != ""} class="text-sm text-base-content/60 mt-1">
        {@caption}
      </figcaption>
    </figure>
    """
  end

  defp render_youtube(assigns) do
    url = get_in(assigns.block, ["props", "url"]) || ""
    video_id = youtube_video_id(url)
    assigns = assign(assigns, :video_id, video_id)

    ~H"""
    <div :if={@video_id} class="mb-4" style="position:relative;padding-bottom:56.25%;height:0;overflow:hidden;border-radius:8px">
      <iframe
        src={"https://www.youtube-nocookie.com/embed/#{@video_id}"}
        style="position:absolute;top:0;left:0;width:100%;height:100%"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen
      >
      </iframe>
    </div>
    """
  end

  defp youtube_video_id(url) when is_binary(url) do
    case URI.parse(url) do
      %{host: "youtu.be", path: "/" <> id} ->
        id

      %{host: host, path: "/watch", query: query}
      when host in ["www.youtube.com", "youtube.com"] ->
        URI.decode_query(query || "")["v"]

      %{host: host, path: "/embed/" <> id}
      when host in ["www.youtube.com", "youtube.com"] ->
        id

      %{host: host, path: "/shorts/" <> id}
      when host in ["www.youtube.com", "youtube.com"] ->
        id

      _ ->
        nil
    end
  end

  defp youtube_video_id(_), do: nil

  attr :content, :list, default: []
  attr :highlight, :string, default: nil

  def render_inline_content(assigns) do
    content = assigns.content || []
    assigns = assign(assigns, :items, content)

    ~H"""
    <%= for item <- @items do %>
      {render_inline_item(item, @highlight)}
    <% end %>
    """
  end

  defp render_inline_item(%{"type" => "text", "text" => text, "styles" => styles}, highlight)
       when map_size(styles) > 0 do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> highlight_text(highlight)
    |> maybe_wrap("bold", styles, "<strong>", "</strong>")
    |> maybe_wrap("italic", styles, "<em>", "</em>")
    |> maybe_wrap("strikethrough", styles, "<s>", "</s>")
    |> maybe_wrap("code", styles, "<code class=\"bg-base-200 px-1 rounded text-sm\">", "</code>")
    |> Phoenix.HTML.raw()
  end

  defp render_inline_item(%{"type" => "text", "text" => text}, highlight) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> highlight_text(highlight)
    |> Phoenix.HTML.raw()
  end

  defp render_inline_item(%{"type" => "link", "href" => href, "content" => content}, highlight) do
    text =
      Enum.map_join(content, "", fn item ->
        render_inline_item(item, highlight) |> safe_to_string()
      end)

    if safe_url?(href) do
      {:safe, escaped_href} = Phoenix.HTML.html_escape(href)
      Phoenix.HTML.raw(~s(<a href="#{escaped_href}" class="link link-primary">#{text}</a>))
    else
      Phoenix.HTML.raw(text)
    end
  end

  defp render_inline_item(_, _highlight), do: ""

  defp safe_to_string({:safe, val}), do: val |> IO.iodata_to_binary()
  defp safe_to_string(val) when is_binary(val), do: val

  defp safe_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %{scheme: scheme} when scheme in ~w(http https mailto) -> true
      %{scheme: nil} -> true
      _ -> false
    end
  end

  defp safe_url?(_), do: false

  defp highlight_text(text, nil), do: text
  defp highlight_text(text, ""), do: text

  defp highlight_text(text, query) do
    escaped_query = Regex.escape(query)

    Regex.replace(~r/#{escaped_query}/iu, text, fn match ->
      "<mark class=\"bg-warning/40 rounded-sm\">#{match}</mark>"
    end)
  end

  defp maybe_wrap(text, style_key, styles, open_tag, close_tag) do
    if styles[style_key] do
      "#{open_tag}#{text}#{close_tag}"
    else
      text
    end
  end
end
