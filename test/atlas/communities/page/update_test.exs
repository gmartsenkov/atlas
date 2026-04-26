defmodule Atlas.Communities.Page.UpdateTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Page.Update

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)

    %{owner: owner, community: community, page: page}
  end

  describe "call/6" do
    test "owner can update a page", %{owner: owner, community: community, page: page} do
      content = [
        %{
          "type" => "heading",
          "props" => %{"level" => 1},
          "content" => [%{"type" => "text", "text" => "Updated"}],
          "children" => []
        }
      ]

      assert {:ok, updated, sections} =
               Update.call(page, %{title: "New Title"}, content, community, owner, false)

      assert updated.title == "New Title"
      assert length(sections) >= 1
    end

    test "moderator can update a page", %{community: community, page: page} do
      moderator = user_fixture()

      assert {:ok, _, _} =
               Update.call(page, %{title: "Mod Edit"}, [], community, moderator, true)
    end

    test "random user cannot update a page", %{community: community, page: page} do
      random = user_fixture()

      assert {:error, :unauthorized} =
               Update.call(page, %{title: "Nope"}, [], community, random, false)
    end
  end
end
