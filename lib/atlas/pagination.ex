defmodule Atlas.Pagination do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Repo

  defstruct items: [], total: 0, offset: 0, limit: 20, has_more: false

  def paginate(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    total = query |> exclude(:preload) |> subquery() |> Repo.aggregate(:count)
    items = query |> limit(^limit) |> offset(^offset) |> Repo.all()

    %__MODULE__{
      items: items,
      total: total,
      offset: offset,
      limit: limit,
      has_more: offset + length(items) < total
    }
  end
end
