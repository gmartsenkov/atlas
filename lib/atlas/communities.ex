defmodule Atlas.Communities do
  import Ecto.Query
  alias Atlas.Repo
  alias Atlas.Communities.{Community, CommunityMember, Page}

  def list_communities do
    Community
    |> order_by(:name)
    |> with_member_count()
    |> Repo.all()
  end

  def search_communities(query) when is_binary(query) and query != "" do
    wildcard = "%#{query}%"

    Community
    |> where([c], ilike(c.name, ^wildcard) or ilike(c.description, ^wildcard))
    |> order_by(:name)
    |> with_member_count()
    |> Repo.all()
  end

  def search_communities(_), do: list_communities()

  defp with_member_count(query) do
    from c in query,
      left_join: m in CommunityMember,
      on: m.community_id == c.id,
      group_by: c.id,
      select_merge: %{member_count: count(m.id)}
  end

  def get_community_by_name!(name) do
    Community
    |> Repo.get_by!(name: name)
    |> Repo.preload([:owner, pages: from(p in Page, order_by: p.title)])
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
    Repo.delete_all(
      from m in CommunityMember,
        where: m.user_id == ^user.id and m.community_id == ^community.id
    )

    :ok
  end

  def member?(user, community) do
    Repo.exists?(
      from m in CommunityMember,
        where: m.user_id == ^user.id and m.community_id == ^community.id
    )
  end

  def get_page_by_slugs!(community_name, page_slug) do
    from(p in Page,
      join: c in Community,
      on: c.id == p.community_id,
      where: c.name == ^community_name and p.slug == ^page_slug,
      preload: :community
    )
    |> Repo.one!()
  end

  def create_page(attrs, owner) do
    %Page{}
    |> Page.changeset(Map.put(attrs, "owner_id", owner.id))
    |> Repo.insert()
  end

  def update_page(page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  def change_page(page \\ %Page{}, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end
end
