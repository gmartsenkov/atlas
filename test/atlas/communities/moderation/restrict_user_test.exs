defmodule Atlas.Communities.Moderation.RestrictUserTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager
  alias Atlas.Communities.Moderation.RestrictUser

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    target_user = user_fixture()

    %{owner: owner, community: community, target_user: target_user}
  end

  describe "call/4" do
    test "restricts user and removes membership", %{
      owner: owner,
      community: community,
      target_user: user
    } do
      CommunityManager.join_community(user, community)
      assert CommunityManager.member?(user, community)

      {:ok, restriction} = RestrictUser.call(community, user, owner, %{reason: "Banned"})

      assert restriction.community_id == community.id
      assert restriction.user_id == user.id
      refute CommunityManager.member?(user, community)
    end

    test "returns unauthorized for non-moderator", %{community: community, target_user: user} do
      random_user = user_fixture()

      assert {:error, :unauthorized} =
               RestrictUser.call(community, user, random_user, %{reason: "Nope"})
    end

    test "rolls back membership removal when restriction insert fails", %{
      owner: owner,
      community: community,
      target_user: user
    } do
      CommunityManager.join_community(user, community)

      # First restriction succeeds
      {:ok, _} = RestrictUser.call(community, user, owner, %{reason: "First"})
      refute CommunityManager.member?(user, community)

      # Re-add membership to set up the scenario
      CommunityManager.join_community(user, community)
      assert CommunityManager.member?(user, community)

      # Second restriction fails (duplicate unique constraint)
      {:error, _} = RestrictUser.call(community, user, owner, %{reason: "Duplicate"})

      # Membership should still be intact since the transaction rolled back
      assert CommunityManager.member?(user, community)
    end

    test "allows moderator to restrict", %{community: community, target_user: user} do
      moderator = user_fixture()
      CommunityManager.join_community(moderator, community)
      CommunityManager.set_member_role(community, moderator.id, "moderator")

      {:ok, restriction} = RestrictUser.call(community, user, moderator, %{reason: "Spam"})

      assert restriction.restricted_by_id == moderator.id
    end
  end
end
