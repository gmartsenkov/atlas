defmodule Atlas.Communities.CommunityManager do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Collection, Community, CommunityMember, Page}
  alias Atlas.Repo

  @max_search_length 200

  def list_communities do
    Community
    |> order_by(:name)
    |> with_member_count()
    |> Repo.all()
  end

  def search_communities(query) when is_binary(query) do
    query = query |> String.trim() |> String.slice(0, @max_search_length)

    if query == "" do
      list_communities()
    else
      escaped =
        query
        |> String.replace("\\", "\\\\")
        |> String.replace("%", "\\%")
        |> String.replace("_", "\\_")

      wildcard = "%#{escaped}%"

      Community
      |> where([c], ilike(c.name, ^wildcard) or ilike(c.description, ^wildcard))
      |> order_by(:name)
      |> with_member_count()
      |> Repo.all()
    end
  end

  def search_communities(_), do: list_communities()

  defp with_member_count(query) do
    from c in query,
      left_join: m in CommunityMember,
      on: m.community_id == c.id,
      group_by: c.id,
      select_merge: %{member_count: count(m.id)}
  end

  def get_community_by_name(name) do
    case Repo.get_by(Community, name: name) do
      nil ->
        {:error, :not_found}

      community ->
        {:ok,
         Repo.preload(community, [
           :owner,
           pages: from(p in Page, order_by: [p.sort_order, p.title]),
           collections: from(c in Collection, order_by: [c.sort_order, c.name])
         ])}
    end
  end

  def create_community(attrs, owner) do
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

  def change_community(community \\ %Community{}, attrs \\ %{}) do
    Community.changeset(community, attrs)
  end

  def update_community(%Community{} = community, attrs) do
    community
    |> Community.edit_changeset(attrs)
    |> Repo.update()
  end

  def change_community_edit(%Community{} = community, attrs \\ %{}) do
    Community.edit_changeset(community, attrs)
  end

  def join_community(user, community) do
    %CommunityMember{}
    |> CommunityMember.changeset(%{user_id: user.id, community_id: community.id})
    |> Repo.insert()
  end

  def leave_community(user, community) do
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

  def member?(user, community) do
    Repo.exists?(
      from m in CommunityMember,
        where: m.user_id == ^user.id and m.community_id == ^community.id
    )
  end
end
