defmodule Atlas.Communities.HelpersTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Helpers

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  describe "batch_reorder/3" do
    test "returns :ok for empty list" do
      assert :ok = Helpers.batch_reorder(Atlas.Communities.Collection, 1, [])
    end

    test "reorders collections by given id order" do
      owner = user_fixture()
      community = community_fixture(owner)
      c1 = collection_fixture(community, %{"name" => "Alpha"})
      c2 = collection_fixture(community, %{"name" => "Beta"})
      c3 = collection_fixture(community, %{"name" => "Gamma"})

      assert :ok = Helpers.batch_reorder(Atlas.Communities.Collection, community.id, [c3.id, c1.id, c2.id])

      [first, second, third] = Atlas.Communities.list_collections(community)
      assert first.id == c3.id
      assert second.id == c1.id
      assert third.id == c2.id
    end
  end

  describe "dollar/1" do
    test "returns positional parameter string" do
      assert "$1" = Helpers.dollar(1)
      assert "$42" = Helpers.dollar(42)
    end
  end
end
