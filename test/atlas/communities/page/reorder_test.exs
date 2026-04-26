defmodule Atlas.Communities.Page.ReorderTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Page.Reorder

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    p1 = page_fixture(community, owner, %{"title" => "Alpha", "slug" => "alpha"})
    p2 = page_fixture(community, owner, %{"title" => "Beta", "slug" => "beta"})
    p3 = page_fixture(community, owner, %{"title" => "Gamma", "slug" => "gamma"})

    %{owner: owner, community: community, pages: [p1, p2, p3]}
  end

  describe "call/4" do
    test "owner can reorder pages", %{owner: owner, community: community, pages: [p1, p2, p3]} do
      assert :ok = Reorder.call(community, [p3.id, p1.id, p2.id], owner, false)
    end

    test "moderator can reorder pages", %{community: community, pages: [p1, p2, p3]} do
      moderator = user_fixture()

      assert :ok = Reorder.call(community, [p2.id, p3.id, p1.id], moderator, true)
    end

    test "random user cannot reorder pages", %{community: community, pages: [p1, p2, p3]} do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Reorder.call(community, [p3.id, p2.id, p1.id], random, false)
    end
  end
end
