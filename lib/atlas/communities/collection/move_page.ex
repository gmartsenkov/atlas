defmodule Atlas.Communities.Collection.MovePage do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CollectionsContext

  def call(page, collection_id, actor, community, is_moderator) do
    with :ok <- authorize(actor, community, is_moderator) do
      if collection_id do
        CollectionsContext.assign_page_to_collection(page, collection_id)
      else
        CollectionsContext.remove_page_from_collection(page)
      end
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
