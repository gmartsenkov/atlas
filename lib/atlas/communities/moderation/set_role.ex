defmodule Atlas.Communities.Moderation.SetRole do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CommunityManager

  def call(community, user_id, role, actor) do
    with :ok <- authorize(actor, community),
         {:ok, member} <- CommunityManager.get_member(community, user_id) do
      CommunityManager.update_member_role(member, role)
    end
  end

  defp authorize(actor, community) do
    if Authorization.community_owner?(actor, community) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
