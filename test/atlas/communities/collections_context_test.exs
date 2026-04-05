defmodule Atlas.Communities.CollectionsContextTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Collection
  alias Atlas.Communities.CollectionsContext

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    %{owner: owner, community: community}
  end

  describe "list_collections/1" do
    test "returns collections ordered by sort_order, then name", %{community: community} do
      collection_fixture(community, %{"name" => "Zebra"})
      collection_fixture(community, %{"name" => "Alpha"})

      collections = CollectionsContext.list_collections(community)
      assert length(collections) == 2
      names = Enum.map(collections, & &1.name)
      assert names == ["Alpha", "Zebra"]
    end

    test "returns empty list for community with no collections", %{owner: owner} do
      other = community_fixture(owner)
      assert [] == CollectionsContext.list_collections(other)
    end
  end

  describe "get_collection/1" do
    test "returns collection by id", %{community: community} do
      collection = collection_fixture(community)
      assert {:ok, found} = CollectionsContext.get_collection(collection.id)
      assert found.id == collection.id
    end

    test "returns error for nonexistent id" do
      assert {:error, :not_found} = CollectionsContext.get_collection(-1)
    end
  end

  describe "create_collection/2" do
    test "creates a collection", %{community: community} do
      assert {:ok, collection} =
               CollectionsContext.create_collection(community, %{"name" => "My Collection"})

      assert collection.name == "My Collection"
      assert collection.community_id == community.id
    end

    test "validates name is required", %{community: community} do
      assert {:error, changeset} = CollectionsContext.create_collection(community, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "enforces unique name per community", %{community: community} do
      {:ok, _} = CollectionsContext.create_collection(community, %{"name" => "Unique"})

      assert {:error, changeset} =
               CollectionsContext.create_collection(community, %{"name" => "Unique"})

      assert %{name: ["already exists in this community"]} = errors_on(changeset)
    end
  end

  describe "update_collection/2" do
    test "updates collection name", %{community: community} do
      collection = collection_fixture(community)

      assert {:ok, updated} =
               CollectionsContext.update_collection(collection, %{"name" => "Renamed"})

      assert updated.name == "Renamed"
    end
  end

  describe "delete_collection/1" do
    test "deletes a collection", %{community: community} do
      collection = collection_fixture(community)
      assert {:ok, _} = CollectionsContext.delete_collection(collection)
      assert {:error, :not_found} = CollectionsContext.get_collection(collection.id)
    end
  end

  describe "change_collection/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = CollectionsContext.change_collection()
      assert %Ecto.Changeset{} = CollectionsContext.change_collection(%Collection{}, %{name: "x"})
    end
  end

  describe "reorder_collections/2" do
    test "reorders collections", %{community: community} do
      c1 = collection_fixture(community, %{"name" => "First"})
      c2 = collection_fixture(community, %{"name" => "Second"})

      assert :ok = CollectionsContext.reorder_collections(community, [c2.id, c1.id])

      [first, second] = CollectionsContext.list_collections(community)
      assert first.id == c2.id
      assert second.id == c1.id
    end
  end

  describe "assign_page_to_collection/2" do
    test "assigns a page to a collection", %{community: community, owner: owner} do
      page = page_fixture(community, owner)
      collection = collection_fixture(community)

      assert {:ok, updated} = CollectionsContext.assign_page_to_collection(page, collection.id)
      assert updated.collection_id == collection.id
    end

    test "rejects cross-community assignment", %{owner: owner} do
      c1 = community_fixture(owner)
      c2 = community_fixture(owner)
      page = page_fixture(c1, owner)
      collection = collection_fixture(c2)

      assert {:error, :invalid_collection} =
               CollectionsContext.assign_page_to_collection(page, collection.id)
    end
  end

  describe "remove_page_from_collection/1" do
    test "removes page from collection", %{community: community, owner: owner} do
      page = page_fixture(community, owner)
      collection = collection_fixture(community)
      {:ok, page} = CollectionsContext.assign_page_to_collection(page, collection.id)

      assert {:ok, updated} = CollectionsContext.remove_page_from_collection(page)
      assert is_nil(updated.collection_id)
    end
  end
end
