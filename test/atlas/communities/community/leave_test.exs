defmodule Atlas.Communities.Community.LeaveTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Community.{Join, Leave}
  alias Atlas.Communities.CommunityManager

  setup do
    owner = user_fixture()
    community = community_fixture(owner)

    %{owner: owner, community: community}
  end

  describe "call/2" do
    test "member can leave a community", %{community: community} do
      user = user_fixture()
      {:ok, _} = Join.call(user, community)

      assert :ok = Leave.call(user, community)
      refute CommunityManager.member?(user, community)
    end

    test "owner cannot leave their community", %{owner: owner, community: community} do
      assert {:error, :owner_cannot_leave} = Leave.call(owner, community)
    end

    test "non-member gets not_a_member error", %{community: community} do
      user = user_fixture()

      assert {:error, :not_a_member} = Leave.call(user, community)
    end
  end
end
