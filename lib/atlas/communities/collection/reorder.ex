defmodule Atlas.Communities.Collection.Reorder do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CollectionsContext

  def call(community, ids, actor, is_moderator) do
    with :ok <- authorize(actor, community, is_moderator) do
      CollectionsContext.reorder_collections(community, ids)
    end
  end

  defp authorize(actor, community, is_moderator) do
    if Authorization.can_manage_collections?(actor, community, is_moderator) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
