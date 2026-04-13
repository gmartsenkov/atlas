defmodule Atlas.Communities.CommunityManager do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Collection, Community, CommunityMember, Page}
  alias Atlas.Pagination
  alias Atlas.Repo

  @max_search_length 200

  def list_communities(opts \\ []) do
    Community
    |> order_by(:name)
    |> with_member_count()
    |> Pagination.paginate(opts)
  end

  def search_communities(query, opts \\ [])

  def search_communities(query, opts) when is_binary(query) do
    query = query |> String.trim() |> String.slice(0, @max_search_length)

    if query == "" do
      list_communities(opts)
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
      |> Pagination.paginate(opts)
    end
  end

  def search_communities(_, opts), do: list_communities(opts)

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

  def moderator?(nil, _community), do: false

  def moderator?(user, community) do
    Repo.exists?(
      from m in CommunityMember,
        where:
          m.user_id == ^user.id and
            m.community_id == ^community.id and
            m.role == "moderator"
    )
  end

  def set_member_role(community, user_id, role) do
    case Repo.get_by(CommunityMember, community_id: community.id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      member ->
        member
        |> CommunityMember.role_changeset(%{role: role})
        |> Repo.update()
    end
  end

  def community_member_roles(community) do
    moderator_ids =
      from(m in CommunityMember,
        where: m.community_id == ^community.id and m.role == "moderator",
        select: m.user_id
      )
      |> Repo.all()

    moderator_ids
    |> Map.new(&{&1, :moderator})
    |> Map.put(community.owner_id, :owner)
  end

  def list_community_members(community, opts \\ []) do
    search = Keyword.get(opts, :search)

    query =
      from(m in CommunityMember,
        where: m.community_id == ^community.id,
        join: u in assoc(m, :user),
        preload: [user: u],
        order_by: [
          desc:
            fragment(
              "CASE WHEN ? = ? THEN 2 WHEN ? = 'moderator' THEN 1 ELSE 0 END",
              m.user_id,
              ^community.owner_id,
              m.role
            ),
          asc: m.inserted_at
        ]
      )

    query =
      if search && String.trim(search) != "" do
        escaped =
          search
          |> String.trim()
          |> String.slice(0, 100)
          |> String.replace("\\", "\\\\")
          |> String.replace("%", "\\%")
          |> String.replace("_", "\\_")

        wildcard = "%#{escaped}%"
        from [m, u] in query, where: ilike(u.nickname, ^wildcard)
      else
        query
      end

    Pagination.paginate(query, opts)
  end

  def list_community_moderators(community) do
    from(m in CommunityMember,
      where: m.community_id == ^community.id and m.role == "moderator",
      preload: [:user],
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  def list_user_communities(user, limit \\ 6) do
    from(c in Community,
      join: m in CommunityMember,
      on: m.community_id == c.id,
      where: m.user_id == ^user.id,
      order_by: [desc: m.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def list_user_moderated_communities(user) do
    from(c in Community,
      left_join: m in CommunityMember,
      on: m.community_id == c.id and m.user_id == ^user.id and m.role == "moderator",
      where: c.owner_id == ^user.id or not is_nil(m.id),
      order_by: c.name,
      distinct: true
    )
    |> Repo.all()
  end

  def search_community_members(community, query) when is_binary(query) do
    query = query |> String.trim() |> String.slice(0, 100)

    if query == "" do
      []
    else
      escaped =
        query
        |> String.replace("\\", "\\\\")
        |> String.replace("%", "\\%")
        |> String.replace("_", "\\_")

      wildcard = "%#{escaped}%"

      from(m in CommunityMember,
        join: u in assoc(m, :user),
        where:
          m.community_id == ^community.id and m.role != "moderator" and
            m.user_id != ^community.owner_id and ilike(u.nickname, ^wildcard),
        preload: [user: u],
        order_by: [asc: u.nickname],
        limit: 10
      )
      |> Repo.all()
    end
  end
end
