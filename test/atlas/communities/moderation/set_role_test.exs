defmodule Atlas.Communities.Moderation.SetRoleTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager
  alias Atlas.Communities.Moderation.SetRole

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    CommunityManager.join_community(member, community)

    %{owner: owner, community: community, member: member}
  end

  describe "call/4" do
    test "owner can promote member to moderator", %{
      owner: owner,
      community: community,
      member: member
    } do
      {:ok, updated} = SetRole.call(community, member.id, "moderator", owner)

      assert updated.role == "moderator"
      assert CommunityManager.moderator?(member, community)
    end

    test "owner can demote moderator to member", %{
      owner: owner,
      community: community,
      member: member
    } do
      CommunityManager.set_member_role(community, member.id, "moderator")
      assert CommunityManager.moderator?(member, community)

      {:ok, updated} = SetRole.call(community, member.id, "member", owner)

      assert updated.role == "member"
      refute CommunityManager.moderator?(member, community)
    end

    test "non-owner cannot set roles", %{community: community, member: member} do
      random_user = user_fixture()

      assert {:error, :unauthorized} =
               SetRole.call(community, member.id, "moderator", random_user)
    end

    test "moderator cannot set roles", %{community: community, member: member} do
      moderator = user_fixture()
      CommunityManager.join_community(moderator, community)
      CommunityManager.set_member_role(community, moderator.id, "moderator")

      assert {:error, :unauthorized} =
               SetRole.call(community, member.id, "moderator", moderator)
    end

    test "returns not_found for non-member", %{owner: owner, community: community} do
      non_member = user_fixture()

      assert {:error, :not_found} =
               SetRole.call(community, non_member.id, "moderator", owner)
    end
  end
end
