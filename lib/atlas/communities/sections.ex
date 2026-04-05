defmodule Atlas.Communities.Sections do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Proposal, Section}
  alias Atlas.Repo

  def list_sections(page_id) do
    from(s in Section, where: s.page_id == ^page_id, order_by: s.sort_order)
    |> Repo.all()
  end

  def get_section(id) do
    case Repo.get(Section, id) do
      nil -> {:error, :not_found}
      section -> {:ok, Repo.preload(section, proposals: [:author])}
    end
  end

  def save_page_content(page, blocks) when is_list(blocks) do
    splits = split_blocks_into_sections(blocks)
    existing = list_sections(page.id)

    multi =
      Ecto.Multi.new()
      |> upsert_sections(splits, existing, page.id)
      |> cleanup_extra_sections(existing, length(splits))

    case Repo.transaction(multi) do
      {:ok, _results} ->
        {:ok, list_sections(page.id)}

      {:error, _key, reason, _changes} ->
        {:error, reason}
    end
  end

  defp upsert_sections(multi, splits, existing, page_id) do
    splits
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {content, idx}, multi ->
      upsert_section(multi, Enum.at(existing, idx), content, idx, page_id)
    end)
  end

  defp upsert_section(multi, nil, content, idx, page_id) do
    Ecto.Multi.insert(multi, {:section, idx}, fn _changes ->
      Section.changeset(%Section{}, %{content: content, sort_order: idx, page_id: page_id})
    end)
  end

  defp upsert_section(multi, section, content, idx, _page_id) do
    Ecto.Multi.update(multi, {:section, idx}, fn _changes ->
      Section.changeset(section, %{content: content, sort_order: idx})
    end)
  end

  defp cleanup_extra_sections(multi, existing, keep_count) do
    sections_to_check = Enum.drop(existing, keep_count)

    if sections_to_check == [] do
      multi
    else
      Ecto.Multi.run(multi, :cleanup_sections, fn repo, _changes ->
        section_ids = Enum.map(sections_to_check, & &1.id)

        ids_with_pending =
          from(p in Proposal,
            where: p.section_id in ^section_ids and p.status == "pending",
            select: p.section_id
          )
          |> repo.all()
          |> MapSet.new()

        for section <- sections_to_check,
            !MapSet.member?(ids_with_pending, section.id) do
          repo.delete!(section)
        end

        {:ok, :cleaned}
      end)
    end
  end

  def split_blocks_into_sections(blocks) when is_list(blocks) do
    {sections_reversed, current_blocks} =
      Enum.reduce(blocks, {[], []}, fn block, {sections, acc} ->
        split_block(block, sections, acc)
      end)

    Enum.reverse([Enum.reverse(current_blocks) | sections_reversed])
  end

  defp split_block(block, sections, acc) do
    is_section_heading =
      block["type"] == "heading" and get_in(block, ["props", "level"]) in [1, 2]

    case {is_section_heading, acc} do
      {true, []} -> {sections, [block]}
      {true, _} -> {[Enum.reverse(acc) | sections], [block]}
      {false, _} -> {sections, [block | acc]}
    end
  end

  def merge_sections_content(sections) when is_list(sections) do
    sections
    |> Enum.sort_by(& &1.sort_order)
    |> Enum.flat_map(&(&1.content || []))
  end

  def title_from_blocks([%{"type" => "heading", "props" => %{"level" => level}} = block | _])
      when level in [1, 2] do
    get_in(block, ["content", Access.at(0), "text"])
  end

  def title_from_blocks(_), do: nil

  def section_title(%Section{content: content}) when is_list(content) do
    title_from_blocks(content) || "Untitled"
  end

  def section_title(_), do: "Untitled"

  def extract_headings(sections) when is_list(sections) do
    sections
    |> Enum.sort_by(& &1.sort_order)
    |> Enum.flat_map(fn section ->
      (section.content || [])
      |> Enum.filter(fn block ->
        block["type"] == "heading" and block["id"]
      end)
      |> Enum.map(fn block ->
        %{
          id: block["id"],
          text: get_in(block, ["content", Access.at(0), "text"]) || "Untitled",
          level: get_in(block, ["props", "level"]) || 1
        }
      end)
    end)
  end

  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.trim()
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  def slugify(_), do: ""
end
