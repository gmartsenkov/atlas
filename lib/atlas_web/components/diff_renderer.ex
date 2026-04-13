defmodule AtlasWeb.DiffRenderer do
  @moduledoc false
  use Phoenix.Component
  import AtlasWeb.BlockRenderer

  alias Atlas.Communities.ContentDiff

  attr :old_blocks, :list, required: true
  attr :new_blocks, :list, required: true

  def render_diff(assigns) do
    old = assigns.old_blocks || []
    new = assigns.new_blocks || []
    ops = ContentDiff.diff_blocks(old, new)
    assigns = assign(assigns, :ops, ops)

    ~H"""
    <%= if @ops == [] do %>
      <p class="text-base-content/40 italic">No changes</p>
    <% else %>
      <.render_diff_op :for={op <- @ops} op={op} />
    <% end %>
    """
  end

  attr :old_blocks, :list, required: true
  attr :new_blocks, :list, required: true
  attr :context, :integer, default: 1

  def render_collapsed_diff(assigns) do
    old = assigns.old_blocks || []
    new = assigns.new_blocks || []
    ops = ContentDiff.collapsed_diff_blocks(old, new, assigns.context)
    assigns = assign(assigns, :ops, ops)

    ~H"""
    <%= if @ops == [] do %>
      <p class="text-base-content/40 italic">No changes</p>
    <% else %>
      <%= for op <- @ops do %>
        <%= case op do %>
          <% {:separator, count} -> %>
            <div class="py-2 text-center text-xs text-base-content/30 select-none">
              ··· {count} unchanged {if count == 1, do: "block", else: "blocks"} ···
            </div>
          <% _ -> %>
            <.render_diff_op op={op} />
        <% end %>
      <% end %>
    <% end %>
    """
  end

  attr :op, :any, required: true

  def render_diff_op(assigns) do
    ~H"""
    <%= case @op do %>
      <% {:eq, block} -> %>
        <.render_block block={block} />
      <% {:del, block} -> %>
        <div class="bg-error/10 border-l-4 border-error/40 pl-3 -ml-3">
          <.render_deleted_block block={block} />
        </div>
      <% {:ins, block} -> %>
        <div class="bg-success/10 border-l-4 border-success/40 pl-3 -ml-3">
          <.render_block block={block} />
        </div>
      <% {:mod, old_block, new_block} -> %>
        <.render_modified_block old_block={old_block} new_block={new_block} />
    <% end %>
    """
  end

  attr :old_block, :map, required: true
  attr :new_block, :map, required: true

  def render_modified_block(assigns) do
    words = ContentDiff.diff_words(assigns.old_block, assigns.new_block)
    type = assigns.new_block["type"]
    assigns = assign(assigns, words: words, type: type)

    ~H"""
    <div class="bg-warning/5 border-l-4 border-warning/40 pl-3 -ml-3">
      <.render_modified_tag type={@type} block={@new_block} words={@words} />
    </div>
    """
  end

  attr :type, :string, required: true
  attr :block, :map, required: true
  attr :words, :list, required: true

  defp render_modified_tag(assigns) do
    ~H"""
    <%= case @type do %>
      <% "heading" -> %>
        <.render_modified_heading block={@block} words={@words} />
      <% "paragraph" -> %>
        <p class="mb-4 leading-relaxed"><.render_word_diff words={@words} /></p>
      <% "bulletListItem" -> %>
        <li class="ml-6 list-disc mb-1"><.render_word_diff words={@words} /></li>
      <% "numberedListItem" -> %>
        <li class="ml-6 list-decimal mb-1"><.render_word_diff words={@words} /></li>
      <% "checkListItem" -> %>
        <div class="flex items-start gap-2 mb-1">
          <input type="checkbox" checked={get_in(@block, ["props", "checked"])} disabled class="mt-1" />
          <span><.render_word_diff words={@words} /></span>
        </div>
      <% _ -> %>
        <div class="mb-4"><.render_word_diff words={@words} /></div>
    <% end %>
    """
  end

  defp render_modified_heading(assigns) do
    level = get_in(assigns.block, ["props", "level"]) || 1
    assigns = assign(assigns, :level, level)

    ~H"""
    <%= case @level do %>
      <% 1 -> %>
        <h1 class="text-3xl font-bold mt-8 mb-4"><.render_word_diff words={@words} /></h1>
      <% 2 -> %>
        <h2 class="text-2xl font-semibold mt-6 mb-3"><.render_word_diff words={@words} /></h2>
      <% 3 -> %>
        <h3 class="text-xl font-semibold mt-4 mb-2"><.render_word_diff words={@words} /></h3>
      <% _ -> %>
        <h4 class="text-lg font-medium mt-4 mb-2"><.render_word_diff words={@words} /></h4>
    <% end %>
    """
  end

  attr :words, :list, required: true

  def render_word_diff(assigns) do
    ~H"""
    <%= for {op, word} <- @words do %>
      <%= case op do %>
        <% :eq -> %>
          {word}
        <% :del -> %>
          <span class="bg-error/20 line-through text-error/70">{word}</span>
        <% :ins -> %>
          <span class="bg-success/20">{word}</span>
      <% end %>
    <% end %>
    """
  end

  attr :block, :map, required: true

  defp render_deleted_block(assigns) do
    ~H"""
    <div class="line-through text-error/70">
      <.render_block block={@block} />
    </div>
    """
  end
end
