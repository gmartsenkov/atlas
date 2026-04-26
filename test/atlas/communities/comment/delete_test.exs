defmodule Atlas.Communities.Comment.DeleteTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Comment.Delete

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)

    %{owner: owner, community: community, page: page}
  end

  describe "call/4" do
    test "author can delete their own comment", %{page: page} do
      author = user_fixture()
      comment = comment_fixture(page, author)

      assert {:ok, deleted} = Delete.call(comment, page, author, false)
      assert deleted.deleted == true
    end

    test "page owner can delete any comment", %{owner: owner, page: page} do
      author = user_fixture()
      comment = comment_fixture(page, author)

      assert {:ok, deleted} = Delete.call(comment, page, owner, false)
      assert deleted.deleted == true
    end

    test "moderator can delete any comment", %{page: page} do
      author = user_fixture()
      comment = comment_fixture(page, author)
      moderator = user_fixture()

      assert {:ok, deleted} = Delete.call(comment, page, moderator, true)
      assert deleted.deleted == true
    end

    test "random user cannot delete comment", %{page: page} do
      author = user_fixture()
      comment = comment_fixture(page, author)
      random = user_fixture()

      assert {:error, :unauthorized} = Delete.call(comment, page, random, false)
    end
  end
end
