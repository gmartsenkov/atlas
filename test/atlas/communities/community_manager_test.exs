defmodule Atlas.Communities.CommunityManagerTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.Community
  alias Atlas.Communities.CommunityManager

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    %{owner: owner}
  end

  describe "list_communities/0" do
    test "returns all communities ordered by name", %{owner: owner} do
      community_fixture(owner, %{"name" => "Zebra", "description" => "Z"})
      community_fixture(owner, %{"name" => "Alpha", "description" => "A"})

      result = CommunityManager.list_communities()
      names = Enum.map(result, & &1.name)
      assert "Alpha" in names
      assert "Zebra" in names
      assert Enum.find_index(names, &(&1 == "Alpha")) < Enum.find_index(names, &(&1 == "Zebra"))
    end

    test "includes member_count", %{owner: owner} do
      community = community_fixture(owner)
      result = CommunityManager.list_communities()
      found = Enum.find(result, &(&1.id == community.id))
      assert found.member_count == 1
    end
  end

  describe "search_communities/1" do
    test "returns all when query is empty", %{owner: owner} do
      community_fixture(owner)
      assert CommunityManager.search_communities("") != []
    end

    test "filters by name", %{owner: owner} do
      community_fixture(owner, %{"name" => "UniqueTestName", "description" => "desc"})
      community_fixture(owner, %{"name" => "Other", "description" => "desc"})

      results = CommunityManager.search_communities("UniqueTest")
      assert length(results) == 1
      assert hd(results).name == "UniqueTestName"
    end

    test "filters by description", %{owner: owner} do
      community_fixture(owner, %{"name" => "Comm1", "description" => "SpecialDescription"})
      results = CommunityManager.search_communities("SpecialDescription")
      assert length(results) == 1
    end

    test "returns all for non-binary input", %{owner: owner} do
      community_fixture(owner)
      assert CommunityManager.search_communities(nil) != []
    end
  end

  describe "get_community_by_name/1" do
    test "returns community with preloads", %{owner: owner} do
      community = community_fixture(owner)
      assert {:ok, found} = CommunityManager.get_community_by_name(community.name)
      assert found.id == community.id
      assert found.owner.id == owner.id
    end

    test "returns error for nonexistent name" do
      assert {:error, :not_found} = CommunityManager.get_community_by_name("nope")
    end
  end

  describe "create_community/2" do
    test "creates community and membership", %{owner: owner} do
      attrs = %{"name" => "NewComm", "description" => "desc"}
      assert {:ok, community} = CommunityManager.create_community(attrs, owner)
      assert community.name == "NewComm"
      assert CommunityManager.member?(owner, community)
    end

    test "returns error for invalid attrs", %{owner: owner} do
      assert {:error, changeset} = CommunityManager.create_community(%{}, owner)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "change_community/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = CommunityManager.change_community()
      assert %Ecto.Changeset{} = CommunityManager.change_community(%Community{}, %{name: "x"})
    end
  end

  describe "update_community/2" do
    test "updates editable fields", %{owner: owner} do
      community = community_fixture(owner)

      assert {:ok, updated} =
               CommunityManager.update_community(community, %{"description" => "New desc"})

      assert updated.description == "New desc"
    end
  end

  describe "change_community_edit/2" do
    test "returns a changeset", %{owner: owner} do
      community = community_fixture(owner)
      assert %Ecto.Changeset{} = CommunityManager.change_community_edit(community)
    end
  end

  describe "join_community/2" do
    test "adds user as member", %{owner: owner} do
      community = community_fixture(owner)
      new_user = user_fixture()
      assert {:ok, _} = CommunityManager.join_community(new_user, community)
      assert CommunityManager.member?(new_user, community)
    end

    test "returns error for duplicate membership", %{owner: owner} do
      community = community_fixture(owner)
      # owner is already a member
      assert {:error, _} = CommunityManager.join_community(owner, community)
    end
  end

  describe "leave_community/2" do
    test "removes membership", %{owner: owner} do
      community = community_fixture(owner)
      new_user = user_fixture()
      {:ok, _} = CommunityManager.join_community(new_user, community)

      assert :ok = CommunityManager.leave_community(new_user, community)
      refute CommunityManager.member?(new_user, community)
    end

    test "owner cannot leave", %{owner: owner} do
      community = community_fixture(owner)
      assert {:error, :owner_cannot_leave} = CommunityManager.leave_community(owner, community)
    end

    test "returns error if not a member", %{owner: owner} do
      community = community_fixture(owner)
      other = user_fixture()
      assert {:error, :not_a_member} = CommunityManager.leave_community(other, community)
    end
  end

  describe "member?/2" do
    test "returns true for members, false otherwise", %{owner: owner} do
      community = community_fixture(owner)
      assert CommunityManager.member?(owner, community)
      refute CommunityManager.member?(user_fixture(), community)
    end
  end
end
