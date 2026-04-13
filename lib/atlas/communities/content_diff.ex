defmodule Atlas.Communities.ContentDiff do
  @moduledoc false

  @doc """
  Computes a block-level diff between two lists of BlockNote JSON blocks.

  Returns a list of operations:
  - `{:eq, block}` — unchanged block
  - `{:del, block}` — removed block
  - `{:ins, block}` — added block
  - `{:mod, old_block, new_block}` — modified block (same type, different content)
  """
  def diff_blocks(old_blocks, new_blocks) do
    old_blocks = old_blocks || []
    new_blocks = new_blocks || []

    old_fps = Enum.map(old_blocks, &fingerprint/1)
    new_fps = Enum.map(new_blocks, &fingerprint/1)

    List.myers_difference(old_fps, new_fps)
    |> expand_ops(old_blocks, new_blocks)
    |> collapse_modifications()
  end

  @doc """
  Computes a word-level diff between two blocks' text content.

  Returns a list of `{:eq | :del | :ins, word}` tuples.
  """
  def diff_words(old_block, new_block) do
    old_words = old_block |> extract_text() |> split_words()
    new_words = new_block |> extract_text() |> split_words()

    List.myers_difference(old_words, new_words)
    |> Enum.flat_map(fn
      {:eq, words} -> Enum.map(words, &{:eq, &1})
      {:del, words} -> Enum.map(words, &{:del, &1})
      {:ins, words} -> Enum.map(words, &{:ins, &1})
    end)
  end

  @doc """
  Recursively extracts plain text from a block's content array.
  """
  def extract_text(%{"content" => content}) when is_list(content) do
    Enum.map_join(content, "", &extract_item_text/1)
  end

  def extract_text(_), do: ""

  defp extract_item_text(%{"type" => "text", "text" => text}), do: text

  defp extract_item_text(%{"type" => "link", "content" => content}) when is_list(content) do
    Enum.map_join(content, "", &extract_item_text/1)
  end

  defp extract_item_text(_), do: ""

  defp fingerprint(block) do
    type = block["type"]

    props =
      case type do
        "heading" -> %{"level" => get_in(block, ["props", "level"])}
        "checkListItem" -> %{"checked" => get_in(block, ["props", "checked"])}
        "image" -> %{"url" => get_in(block, ["props", "url"])}
        "youtube" -> %{"url" => get_in(block, ["props", "url"])}
        _ -> %{}
      end

    text = extract_text(block)
    {type, props, text}
  end

  defp expand_ops(myers_ops, old_blocks, new_blocks) do
    {ops, _old_idx, _new_idx} =
      Enum.reduce(myers_ops, {[], 0, 0}, fn
        {:eq, items}, {acc, old_idx, new_idx} ->
          count = length(items)
          blocks = Enum.slice(old_blocks, old_idx, count)
          new_ops = Enum.map(blocks, &{:eq, &1})
          {acc ++ new_ops, old_idx + count, new_idx + count}

        {:del, items}, {acc, old_idx, new_idx} ->
          count = length(items)
          blocks = Enum.slice(old_blocks, old_idx, count)
          new_ops = Enum.map(blocks, &{:del, &1})
          {acc ++ new_ops, old_idx + count, new_idx}

        {:ins, items}, {acc, old_idx, new_idx} ->
          count = length(items)
          blocks = Enum.slice(new_blocks, new_idx, count)
          new_ops = Enum.map(blocks, &{:ins, &1})
          {acc ++ new_ops, old_idx, new_idx + count}
      end)

    ops
  end

  defp collapse_modifications(ops) do
    ops
    |> Enum.chunk_while(
      [],
      fn op, acc ->
        case {acc, op} do
          {[], _} -> {:cont, [op]}
          {[{:del, _} | _], {:del, _}} -> {:cont, acc ++ [op]}
          {[{:del, _} | _], {:ins, _}} -> {:cont, acc ++ [op]}
          {_, _} -> {:cont, acc, [op]}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, acc, []}
      end
    )
    |> Enum.flat_map(&merge_del_ins_chunk/1)
  end

  defp merge_del_ins_chunk(chunk) do
    {dels, rest} =
      Enum.split_with(chunk, fn
        {:del, _} -> true
        _ -> false
      end)

    {inss, others} =
      Enum.split_with(rest, fn
        {:ins, _} -> true
        _ -> false
      end)

    if dels == [] and inss == [] do
      others
    else
      del_blocks = Enum.map(dels, fn {:del, b} -> b end)
      ins_blocks = Enum.map(inss, fn {:ins, b} -> b end)
      others ++ merge_pairs(del_blocks, ins_blocks)
    end
  end

  defp merge_pairs([], []), do: []
  defp merge_pairs([], ins), do: Enum.map(ins, &{:ins, &1})
  defp merge_pairs(dels, []), do: Enum.map(dels, &{:del, &1})

  defp merge_pairs([del | rest_del], [ins | rest_ins]) do
    if del["type"] == ins["type"] and del["type"] not in ["image", "youtube"] do
      [{:mod, del, ins} | merge_pairs(rest_del, rest_ins)]
    else
      [{:del, del} | [{:ins, ins} | merge_pairs(rest_del, rest_ins)]]
    end
  end

  defp split_words(""), do: []

  defp split_words(text) do
    Regex.split(~r/(\s+)/, text, include_captures: true, trim: true)
  end
end
