defmodule Atlas.Communities.Community.Create do
  @moduledoc false

  alias Atlas.Communities.{Community, CommunityMember}
  alias Atlas.Repo

  def call(attrs, owner) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:community, fn _changes ->
      %Community{}
      |> Community.changeset(Map.put(attrs, "owner_id", owner.id))
    end)
    |> Ecto.Multi.insert(:membership, fn %{community: community} ->
      %CommunityMember{}
      |> CommunityMember.changeset(%{user_id: owner.id, community_id: community.id})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{community: community}} -> {:ok, community}
      {:error, :community, changeset, _} -> {:error, changeset}
      {:error, :membership, changeset, _} -> {:error, changeset}
    end
  end
end
