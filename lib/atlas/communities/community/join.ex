defmodule Atlas.Communities.Community.Join do
  @moduledoc false

  alias Atlas.Communities.CommunityMember
  alias Atlas.Repo

  def call(user, community) do
    %CommunityMember{}
    |> CommunityMember.changeset(%{user_id: user.id, community_id: community.id})
    |> Repo.insert()
  end
end
