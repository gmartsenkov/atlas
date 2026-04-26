defmodule Atlas.Communities.Page.Reorder do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.PagesContext

  def call(community, ids, actor, is_moderator) do
    if Authorization.can_manage_collections?(actor, community, is_moderator) do
      PagesContext.reorder_pages(community, ids)
    else
      {:error, :unauthorized}
    end
  end
end
