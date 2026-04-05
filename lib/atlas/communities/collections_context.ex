defmodule Atlas.Communities.CollectionsContext do
  @moduledoc false
  import Ecto.Query

  alias Atlas.Communities.{Collection, Helpers, Page}
  alias Atlas.Repo

  def list_collections(community) do
    from(c in Collection,
      where: c.community_id == ^community.id,
      order_by: [c.sort_order, c.name]
    )
    |> Repo.all()
  end

  def get_collection(id) do
    case Repo.get(Collection, id) do
      nil -> {:error, :not_found}
      collection -> {:ok, collection}
    end
  end

  def create_collection(community, attrs) do
    %Collection{}
    |> Collection.changeset(Map.put(attrs, "community_id", community.id))
    |> Repo.insert()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def change_collection(%Collection{} = collection \\ %Collection{}, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  def reorder_collections(community, ids) when is_list(ids) do
    Helpers.batch_reorder(Collection, community.id, ids)
  end

  def assign_page_to_collection(%Page{} = page, collection_id) do
    collection = Repo.get(Collection, collection_id)

    if collection && collection.community_id == page.community_id do
      page
      |> Page.changeset(%{collection_id: collection_id})
      |> Repo.update()
    else
      {:error, :invalid_collection}
    end
  end

  def remove_page_from_collection(%Page{} = page) do
    page
    |> Page.changeset(%{collection_id: nil})
    |> Repo.update()
  end
end
