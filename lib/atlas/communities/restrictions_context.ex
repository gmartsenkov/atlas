defmodule Atlas.Communities.RestrictionsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.CommunityRestriction
  alias Atlas.Pagination
  alias Atlas.Repo

  def list_community_restrictions(community, opts \\ []) do
    from(r in CommunityRestriction,
      where: r.community_id == ^community.id,
      order_by: [desc: r.inserted_at, desc: r.id],
      preload: [:user, :restricted_by]
    )
    |> Pagination.paginate(opts)
  end

  def create_restriction(community, user, restricted_by, attrs) do
    %CommunityRestriction{}
    |> CommunityRestriction.changeset(
      Map.merge(attrs, %{
        community_id: community.id,
        user_id: user.id,
        restricted_by_id: restricted_by.id
      })
    )
    |> Repo.insert()
  end

  def delete_restriction(restriction) do
    Repo.delete(restriction)
  end

  def get_restriction(id) do
    case Repo.get(CommunityRestriction, id) do
      nil -> {:error, :not_found}
      restriction -> {:ok, Repo.preload(restriction, [:user, :restricted_by])}
    end
  end
end
