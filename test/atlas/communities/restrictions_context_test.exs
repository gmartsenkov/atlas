defmodule Atlas.Communities.RestrictionsContextTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommunityManager
  alias Atlas.Communities.RestrictionsContext

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    moderator = user_fixture()
    target_user = user_fixture()

    %{
      owner: owner,
      community: community,
      moderator: moderator,
      target_user: target_user
    }
  end

  describe "create_restriction/4" do
    test "creates a restriction", %{community: community, target_user: user, moderator: mod} do
      {:ok, restriction} =
        RestrictionsContext.create_restriction(community, user, mod, %{reason: "Spamming"})

      assert restriction.community_id == community.id
      assert restriction.user_id == user.id
      assert restriction.restricted_by_id == mod.id
      assert restriction.reason == "Spamming"
    end

    test "creates a restriction without reason", %{
      community: community,
      target_user: user,
      moderator: mod
    } do
      {:ok, restriction} = RestrictionsContext.create_restriction(community, user, mod, %{})

      assert restriction.community_id == community.id
      assert is_nil(restriction.reason)
    end

    test "removes user from community members", %{
      community: community,
      target_user: user,
      moderator: mod
    } do
      CommunityManager.join_community(user, community)
      assert CommunityManager.member?(user, community)

      {:ok, _} = RestrictionsContext.create_restriction(community, user, mod, %{reason: "Banned"})

      refute CommunityManager.member?(user, community)
    end

    test "rejects duplicate restriction", %{
      community: community,
      target_user: user,
      moderator: mod
    } do
      {:ok, _} = RestrictionsContext.create_restriction(community, user, mod, %{})
      {:error, changeset} = RestrictionsContext.create_restriction(community, user, mod, %{})

      assert %{community_id: ["user is already restricted in this community"]} =
               errors_on(changeset)
    end
  end

  describe "list_community_restrictions/2" do
    test "returns restrictions for community", %{
      community: community,
      target_user: user,
      moderator: mod
    } do
      restriction = restriction_fixture(community, user, mod, %{reason: "Bad behavior"})
      result = RestrictionsContext.list_community_restrictions(community)

      assert length(result.items) == 1
      assert hd(result.items).id == restriction.id
      assert hd(result.items).user.id == user.id
      assert hd(result.items).restricted_by.id == mod.id
    end

    test "does not return restrictions from other communities", %{
      target_user: user,
      moderator: mod
    } do
      other_owner = user_fixture()
      other_community = community_fixture(other_owner)
      _restriction = restriction_fixture(other_community, user, mod)

      my_community = community_fixture(user_fixture())
      result = RestrictionsContext.list_community_restrictions(my_community)

      assert result.items == []
    end

    test "orders by inserted_at desc", %{community: community, moderator: mod} do
      user1 = user_fixture()
      user2 = user_fixture()
      _r1 = restriction_fixture(community, user1, mod)
      _r2 = restriction_fixture(community, user2, mod)

      result = RestrictionsContext.list_community_restrictions(community)
      ids = Enum.map(result.items, & &1.user_id)

      assert ids == [user2.id, user1.id]
    end
  end

  describe "delete_restriction/1" do
    test "deletes a restriction", %{
      community: community,
      target_user: user,
      moderator: mod
    } do
      restriction = restriction_fixture(community, user, mod)
      {:ok, _} = RestrictionsContext.delete_restriction(restriction)

      assert {:error, :not_found} = RestrictionsContext.get_restriction(restriction.id)
    end
  end

  describe "get_restriction/1" do
    test "returns restriction with preloads", %{
      community: community,
      target_user: user,
      moderator: mod
    } do
      restriction = restriction_fixture(community, user, mod, %{reason: "Test"})
      {:ok, fetched} = RestrictionsContext.get_restriction(restriction.id)

      assert fetched.id == restriction.id
      assert fetched.user.id == user.id
      assert fetched.restricted_by.id == mod.id
    end

    test "returns error for nonexistent restriction" do
      assert {:error, :not_found} = RestrictionsContext.get_restriction(0)
    end
  end
end
