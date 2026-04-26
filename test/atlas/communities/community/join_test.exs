defmodule Atlas.Communities.Community.JoinTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Community.Join
  alias Atlas.Communities.CommunityManager

  setup do
    owner = user_fixture()
    community = community_fixture(owner)

    %{community: community}
  end

  describe "call/2" do
    test "user can join a community", %{community: community} do
      user = user_fixture()

      assert {:ok, membership} = Join.call(user, community)
      assert membership.user_id == user.id
      assert membership.community_id == community.id
      assert CommunityManager.member?(user, community)
    end

    test "cannot join the same community twice", %{community: community} do
      user = user_fixture()
      {:ok, _} = Join.call(user, community)

      assert {:error, _changeset} = Join.call(user, community)
    end
  end
end
