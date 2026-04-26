defmodule Atlas.Communities.Collection.Create do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CollectionsContext

  def call(community, attrs, actor, is_moderator) do
    with :ok <- authorize(actor, community, is_moderator) do
      CollectionsContext.create_collection(community, attrs)
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
