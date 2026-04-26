defmodule Atlas.Communities.Community.CreateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures

  alias Atlas.Communities.Community.Create
  alias Atlas.Communities.CommunityManager

  describe "call/2" do
    test "creates community and adds owner as member" do
      owner = user_fixture()

      assert {:ok, community} =
               Create.call(%{"name" => "TestCommunity", "description" => "A test"}, owner)

      assert community.name == "TestCommunity"
      assert community.owner_id == owner.id
      assert CommunityManager.member?(owner, community)
    end

    test "returns error for invalid attrs" do
      owner = user_fixture()

      assert {:error, changeset} = Create.call(%{}, owner)
      assert errors_on(changeset).name
    end

    test "returns error for duplicate name" do
      owner = user_fixture()
      {:ok, _} = Create.call(%{"name" => "Taken", "description" => "First"}, owner)

      assert {:error, changeset} = Create.call(%{"name" => "Taken", "description" => "Second"}, owner)
      assert errors_on(changeset).name
    end
  end
end
