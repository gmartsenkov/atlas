defmodule Atlas.Communities.Collection.MovePageTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Collection.MovePage

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    collection = collection_fixture(community)
    page = page_fixture(community, owner)

    %{owner: owner, community: community, collection: collection, page: page}
  end

  describe "call/5" do
    test "owner can assign a page to a collection", %{
      owner: owner,
      community: community,
      collection: collection,
      page: page
    } do
      assert {:ok, updated} = MovePage.call(page, collection.id, owner, community, false)
      assert updated.collection_id == collection.id
    end

    test "owner can remove a page from a collection", %{
      owner: owner,
      community: community,
      collection: collection,
      page: page
    } do
      {:ok, assigned} = MovePage.call(page, collection.id, owner, community, false)

      assert {:ok, unassigned} = MovePage.call(assigned, nil, owner, community, false)
      assert is_nil(unassigned.collection_id)
    end

    test "moderator can move a page", %{
      community: community,
      collection: collection,
      page: page
    } do
      moderator = user_fixture()

      assert {:ok, _} = MovePage.call(page, collection.id, moderator, community, true)
    end

    test "random user cannot move a page", %{
      community: community,
      collection: collection,
      page: page
    } do
      random = user_fixture()

      assert {:error, :unauthorized} =
               MovePage.call(page, collection.id, random, community, false)
    end
  end
end
