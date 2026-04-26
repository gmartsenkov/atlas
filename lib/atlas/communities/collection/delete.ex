defmodule Atlas.Communities.Collection.Delete do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CollectionsContext

  def call(collection_id, community, actor, is_moderator) do
    with :ok <- authorize(actor, community, is_moderator),
         {:ok, collection} <- CollectionsContext.get_collection(collection_id),
         true <- collection.community_id == community.id || {:error, :not_found} do
      CollectionsContext.delete_collection(collection)
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
