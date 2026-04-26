defmodule Atlas.Communities.Collection.CreateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Collection.Create

  setup do
    owner = user_fixture()
    community = community_fixture(owner)

    %{owner: owner, community: community}
  end

  describe "call/4" do
    test "owner can create a collection", %{owner: owner, community: community} do
      assert {:ok, collection} = Create.call(community, %{"name" => "Guides"}, owner, false)
      assert collection.name == "Guides"
      assert collection.community_id == community.id
    end

    test "moderator can create a collection", %{community: community} do
      moderator = user_fixture()

      assert {:ok, collection} = Create.call(community, %{"name" => "Docs"}, moderator, true)
      assert collection.name == "Docs"
    end

    test "random user cannot create a collection", %{community: community} do
      random = user_fixture()

      assert {:error, :unauthorized} = Create.call(community, %{"name" => "Nope"}, random, false)
    end

    test "returns error for duplicate name", %{owner: owner, community: community} do
      {:ok, _} = Create.call(community, %{"name" => "Guides"}, owner, false)

      assert {:error, changeset} = Create.call(community, %{"name" => "Guides"}, owner, false)
      assert errors_on(changeset).name
    end
  end
end
