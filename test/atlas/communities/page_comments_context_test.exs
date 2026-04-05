defmodule Atlas.Communities.PageCommentsContextTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.PageCommentsContext

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    %{owner: owner, page: page}
  end

  describe "add_page_comment/3" do
    test "creates a comment", %{owner: user, page: page} do
      assert {:ok, comment} = PageCommentsContext.add_page_comment(page, user, %{body: "Hello"})
      assert comment.body == "Hello"
      assert comment.page_id == page.id
      assert comment.author_id == user.id
    end

    test "validates body is required", %{owner: user, page: page} do
      assert {:error, changeset} = PageCommentsContext.add_page_comment(page, user, %{})
      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "list_page_comments/1" do
    test "returns top-level comments ordered by inserted_at", %{owner: user, page: page} do
      {:ok, c1} = PageCommentsContext.add_page_comment(page, user, %{body: "First"})
      {:ok, c2} = PageCommentsContext.add_page_comment(page, user, %{body: "Second"})

      %{items: comments} = PageCommentsContext.list_page_comments(page)
      assert length(comments) == 2
      assert Enum.map(comments, & &1.id) == [c1.id, c2.id]
    end

    test "includes replies preloaded", %{owner: user, page: page} do
      comment = page_comment_fixture(page, user)

      {:ok, _reply} =
        PageCommentsContext.reply_to_page_comment(page, comment, user, %{body: "Reply"})

      %{items: [loaded]} = PageCommentsContext.list_page_comments(page)
      assert length(loaded.replies) == 1
    end
  end

  describe "reply_to_page_comment/4" do
    test "creates a reply to a top-level comment", %{owner: user, page: page} do
      comment = page_comment_fixture(page, user)

      assert {:ok, reply} =
               PageCommentsContext.reply_to_page_comment(page, comment, user, %{body: "A reply"})

      assert reply.parent_id == comment.id
    end

    test "rejects nested replies", %{owner: user, page: page} do
      comment = page_comment_fixture(page, user)

      {:ok, reply} =
        PageCommentsContext.reply_to_page_comment(page, comment, user, %{body: "Reply"})

      assert {:error, :no_nested_replies} =
               PageCommentsContext.reply_to_page_comment(page, reply, user, %{body: "Nested"})
    end
  end

  describe "delete_page_comment/1" do
    test "deletes a comment", %{owner: user, page: page} do
      comment = page_comment_fixture(page, user)
      assert {:ok, _} = PageCommentsContext.delete_page_comment(comment)
      assert {:error, :not_found} = PageCommentsContext.get_page_comment(comment.id)
    end
  end

  describe "get_page_comment/1" do
    test "returns comment with author preloaded", %{owner: user, page: page} do
      comment = page_comment_fixture(page, user)
      assert {:ok, loaded} = PageCommentsContext.get_page_comment(comment.id)
      assert loaded.author.id == user.id
    end

    test "returns error for nonexistent id" do
      assert {:error, :not_found} = PageCommentsContext.get_page_comment(-1)
    end
  end
end
