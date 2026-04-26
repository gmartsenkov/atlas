defmodule Atlas.Communities.Page.CreateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Page.Create

  setup do
    owner = user_fixture()
    community = community_fixture(owner)

    %{owner: owner, community: community}
  end

  describe "call/4" do
    test "owner can create a page", %{owner: owner, community: community} do
      attrs = %{"title" => "My Page", "slug" => "my-page", "community_id" => community.id}

      assert {:ok, page} = Create.call(community, attrs, owner, false)
      assert page.title == "My Page"
      assert page.slug == "my-page"
      assert page.community_id == community.id
      assert page.owner_id == owner.id
    end

    test "moderator can create a page", %{community: community} do
      moderator = user_fixture()
      attrs = %{"title" => "Mod Page", "slug" => "mod-page", "community_id" => community.id}

      assert {:ok, page} = Create.call(community, attrs, moderator, true)
      assert page.title == "Mod Page"
    end

    test "random user cannot create a page", %{community: community} do
      random = user_fixture()
      attrs = %{"title" => "Nope", "slug" => "nope", "community_id" => community.id}

      assert {:error, :unauthorized} = Create.call(community, attrs, random, false)
    end

    test "returns error for invalid attrs", %{owner: owner, community: community} do
      assert {:error, changeset} = Create.call(community, %{"title" => ""}, owner, false)
      assert errors_on(changeset).title
    end
  end
end
