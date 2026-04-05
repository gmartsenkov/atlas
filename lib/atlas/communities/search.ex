defmodule Atlas.Communities.Search do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Page, Section}
  alias Atlas.Repo

  @max_search_length 200

  def search_community_content(community, query) when is_binary(query) do
    query = query |> String.trim() |> String.slice(0, @max_search_length)

    if query == "" do
      []
    else
      do_search_community_content(community, query)
    end
  end

  def search_community_content(_community, _query), do: []

  defp do_search_community_content(community, query) do
    from(s in Section,
      join: p in Page,
      on: p.id == s.page_id,
      where: p.community_id == ^community.id,
      where:
        fragment(
          "? @@ plainto_tsquery('english', ?)",
          s.search_text,
          ^query
        ),
      order_by: [
        desc:
          fragment(
            "ts_rank(?, plainto_tsquery('english', ?))",
            s.search_text,
            ^query
          )
      ],
      select: %{
        section_id: s.id,
        page_id: p.id,
        page_title: p.title,
        page_slug: p.slug,
        snippet:
          fragment(
            """
            ts_headline('english',
              coalesce((
                WITH RECURSIVE all_blocks AS (
                  SELECT b AS block FROM jsonb_array_elements(?) AS b
                  UNION ALL
                  SELECT child AS block FROM all_blocks,
                    jsonb_array_elements(all_blocks.block -> 'children') AS child
                  WHERE jsonb_typeof(all_blocks.block -> 'children') = 'array'
                    AND jsonb_array_length(all_blocks.block -> 'children') > 0
                )
                SELECT string_agg(elem, ' ')
                FROM (
                  SELECT jsonb_array_elements(ab.block -> 'content') ->> 'text' AS elem
                  FROM all_blocks ab
                  WHERE jsonb_typeof(ab.block -> 'content') = 'array'
                ) sub
                WHERE elem IS NOT NULL
              ), ''),
              plainto_tsquery('english', ?),
              'MaxWords=30, MinWords=15, StartSel=«mark», StopSel=«/mark»')
            """,
            s.content,
            ^query
          )
      }
    )
    |> limit(50)
    |> Repo.all()
    |> Enum.map(&sanitize_snippet/1)
  end

  defp sanitize_snippet(%{snippet: snippet} = result) when is_binary(snippet) do
    safe_snippet =
      snippet
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()
      |> String.replace("«mark»", "<mark>")
      |> String.replace("«/mark»", "</mark>")

    %{result | snippet: safe_snippet}
  end

  defp sanitize_snippet(result), do: result
end
