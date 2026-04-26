defmodule Atlas.Communities.Collection.DeleteTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Collection.Delete

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    collection = collection_fixture(community)

    %{owner: owner, community: community, collection: collection}
  end

  describe "call/4" do
    test "owner can delete a collection", %{
      owner: owner,
      community: community,
      collection: collection
    } do
      assert {:ok, deleted} = Delete.call(collection.id, community, owner, false)
      assert deleted.id == collection.id
    end

    test "moderator can delete a collection", %{community: community, collection: collection} do
      moderator = user_fixture()

      assert {:ok, _} = Delete.call(collection.id, community, moderator, true)
    end

    test "random user cannot delete a collection", %{community: community, collection: collection} do
      random = user_fixture()

      assert {:error, :unauthorized} = Delete.call(collection.id, community, random, false)
    end

    test "returns not_found for non-existent collection", %{owner: owner, community: community} do
      assert {:error, :not_found} = Delete.call(0, community, owner, false)
    end

    test "returns not_found for collection from another community", %{
      owner: owner,
      community: community
    } do
      other_owner = user_fixture()
      other_community = community_fixture(other_owner)
      other_collection = collection_fixture(other_community)

      assert {:error, :not_found} = Delete.call(other_collection.id, community, owner, false)
    end
  end
end
