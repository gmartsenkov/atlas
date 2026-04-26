defmodule Atlas.Communities.Community.UpdateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Community.Update

  setup do
    owner = user_fixture()
    community = community_fixture(owner)

    %{owner: owner, community: community}
  end

  describe "call/3" do
    test "owner can update community", %{owner: owner, community: community} do
      assert {:ok, updated} = Update.call(community, %{"description" => "New desc"}, owner)
      assert updated.description == "New desc"
    end

    test "non-owner cannot update community", %{community: community} do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Update.call(community, %{"description" => "Nope"}, random)
    end

    test "returns error for invalid attrs", %{owner: owner, community: community} do
      assert {:error, changeset} =
               Update.call(community, %{"description" => String.duplicate("x", 3000)}, owner)

      assert errors_on(changeset).description
    end
  end
end
