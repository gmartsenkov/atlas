defmodule Atlas.Communities.Collection.ReorderTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Collection.Reorder
  alias Atlas.Communities.CollectionsContext

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    c1 = collection_fixture(community, %{"name" => "Alpha"})
    c2 = collection_fixture(community, %{"name" => "Beta"})
    c3 = collection_fixture(community, %{"name" => "Gamma"})

    %{owner: owner, community: community, collections: [c1, c2, c3]}
  end

  describe "call/4" do
    test "owner can reorder collections", %{
      owner: owner,
      community: community,
      collections: [c1, c2, c3]
    } do
      assert :ok = Reorder.call(community, [c3.id, c1.id, c2.id], owner, false)

      reordered = CollectionsContext.list_collections(community)
      names = Enum.map(reordered, & &1.name)
      assert names == ["Gamma", "Alpha", "Beta"]
    end

    test "moderator can reorder collections", %{
      community: community,
      collections: [c1, c2, c3]
    } do
      moderator = user_fixture()

      assert :ok = Reorder.call(community, [c2.id, c3.id, c1.id], moderator, true)
    end

    test "random user cannot reorder collections", %{
      community: community,
      collections: [c1, c2, c3]
    } do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Reorder.call(community, [c3.id, c2.id, c1.id], random, false)
    end
  end
end
