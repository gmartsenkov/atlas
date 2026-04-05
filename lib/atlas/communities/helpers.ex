defmodule Atlas.Communities.Helpers do
  @moduledoc false

  alias Atlas.Repo

  def batch_reorder(_schema, _community_id, []), do: :ok

  def batch_reorder(schema, community_id, ids) do
    {values_fragment, params} =
      ids
      |> Enum.with_index()
      |> Enum.reduce({[], []}, fn {id, idx}, {frags, params} ->
        offset = length(params)
        frag = "(#{dollar(offset + 1)}::bigint, #{dollar(offset + 2)}::integer)"
        {[frag | frags], params ++ [id, idx]}
      end)

    values_sql = values_fragment |> Enum.reverse() |> Enum.join(", ")
    next = length(params) + 1

    sql = """
    UPDATE #{schema.__schema__(:source)} AS t
    SET sort_order = v.new_order
    FROM (VALUES #{values_sql}) AS v(id, new_order)
    WHERE t.id = v.id AND t.community_id = #{dollar(next)}
    """

    case Repo.query(sql, params ++ [community_id]) do
      {:ok, _} -> :ok
      {:error, _} = error -> error
    end
  end

  def dollar(n), do: "$#{n}"
end
