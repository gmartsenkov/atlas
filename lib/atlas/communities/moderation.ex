defmodule Atlas.Communities.Moderation do
  @moduledoc false

  alias Atlas.Authorization
  alias Atlas.Communities.CommunityManager

  def authorize_moderator(actor, community) do
    is_moderator = CommunityManager.moderator?(actor, community)

    if Authorization.can_moderate_community?(actor, community, is_moderator) do
      :ok
    else
      {:error, :unauthorized}
    end
  end
end
