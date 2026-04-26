defmodule Atlas.Communities.Community.Leave do
  @moduledoc false

  import Ecto.Query

  alias Atlas.Communities.CommunityMember
  alias Atlas.Repo

  def call(user, community) do
    if community.owner_id == user.id do
      {:error, :owner_cannot_leave}
    else
      case Repo.delete_all(
             from m in CommunityMember,
               where: m.user_id == ^user.id and m.community_id == ^community.id
           ) do
        {0, _} -> {:error, :not_a_member}
        {_, _} -> :ok
      end
    end
  end
end
