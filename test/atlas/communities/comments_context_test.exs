defmodule Atlas.Communities.CommentsContextTest do
  use Atlas.DataCase, async: true

  alias Atlas.Communities.{CommentsContext, Sections}

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    %{owner: owner, community: community, page: page}
  end

  describe "add_comment/3 (page)" do
    test "creates a comment", %{owner: user, page: page} do
      assert {:ok, comment} = CommentsContext.add_comment(page, user, %{body: "Hello"})
      assert comment.body == "Hello"
      assert comment.page_id == page.id
      assert comment.author_id == user.id
    end

    test "validates body is required", %{owner: user, page: page} do
      assert {:error, changeset} = CommentsContext.add_comment(page, user, %{})
      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "add_comment/3 (proposal)" do
    test "creates a comment on a proposal", %{owner: user, page: page} do
      author = user_fixture()
      [section | _] = Sections.list_sections(page.id)
      proposal = proposal_fixture(section, author)

      assert {:ok, comment} = CommentsContext.add_comment(proposal, user, %{body: "Looks good"})
      assert comment.body == "Looks good"
      assert comment.proposal_id == proposal.id
      assert comment.author_id == user.id
    end
  end

  describe "list_comments/1" do
    test "returns top-level comments ordered by inserted_at", %{owner: user, page: page} do
      {:ok, c1} = CommentsContext.add_comment(page, user, %{body: "First"})
      {:ok, c2} = CommentsContext.add_comment(page, user, %{body: "Second"})

      %{items: comments} = CommentsContext.list_comments(page)
      assert length(comments) == 2
      assert Enum.map(comments, & &1.id) == [c1.id, c2.id]
    end

    test "includes replies preloaded", %{owner: user, page: page} do
      comment = comment_fixture(page, user)

      {:ok, _reply} =
        CommentsContext.reply_to_comment(page, comment, user, %{body: "Reply"})

      %{items: [loaded]} = CommentsContext.list_comments(page)
      assert length(loaded.replies) == 1
    end
  end

  describe "reply_to_comment/4" do
    test "creates a reply to a top-level comment", %{owner: user, page: page} do
      comment = comment_fixture(page, user)

      assert {:ok, reply} =
               CommentsContext.reply_to_comment(page, comment, user, %{body: "A reply"})

      assert reply.parent_id == comment.id
    end

    test "rejects nested replies", %{owner: user, page: page} do
      comment = comment_fixture(page, user)

      {:ok, reply} =
        CommentsContext.reply_to_comment(page, comment, user, %{body: "Reply"})

      assert {:error, :no_nested_replies} =
               CommentsContext.reply_to_comment(page, reply, user, %{body: "Nested"})
    end

    test "creates a reply to a proposal comment", %{owner: user, page: page} do
      author = user_fixture()
      [section | _] = Sections.list_sections(page.id)
      proposal = proposal_fixture(section, author)
      comment = comment_fixture(proposal, user)

      assert {:ok, reply} =
               CommentsContext.reply_to_comment(proposal, comment, user, %{body: "A reply"})

      assert reply.parent_id == comment.id
      assert reply.proposal_id == proposal.id
    end
  end

  describe "delete_comment/1" do
    test "marks a comment as deleted", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      assert {:ok, deleted} = CommentsContext.delete_comment(comment)
      assert deleted.deleted == true
      assert {:ok, fetched} = CommentsContext.get_comment(comment.id)
      assert fetched.deleted == true
    end
  end

  describe "get_comment/1" do
    test "returns comment with author preloaded", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      assert {:ok, loaded} = CommentsContext.get_comment(comment.id)
      assert loaded.author.id == user.id
    end

    test "returns error for nonexistent id" do
      assert {:error, :not_found} = CommentsContext.get_comment(-1)
    end
  end
end
