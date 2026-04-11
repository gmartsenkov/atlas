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

      %{items: comments} = CommentsContext.list_comments(page, sort: :old)
      assert length(comments) == 2
      assert Enum.map(comments, & &1.id) == [c1.id, c2.id]
    end

    test "includes replies preloaded", %{owner: user, page: page} do
      comment = comment_fixture(page, user)

      {:ok, _reply} =
        CommentsContext.reply_to_comment(page, comment, user, %{body: "Reply"})

      %{items: [loaded]} = CommentsContext.list_comments(page, sort: :old)
      assert length(loaded.replies) == 1
    end
  end

  describe "list_comments/2 sorting" do
    test "sort: :best returns highest-scored first", %{owner: user, page: page} do
      voter = user_fixture()
      {:ok, c1} = CommentsContext.add_comment(page, user, %{body: "Low"})
      {:ok, c2} = CommentsContext.add_comment(page, user, %{body: "High"})
      {:ok, _} = CommentsContext.vote_comment(voter, c2.id, 1)

      %{items: comments} = CommentsContext.list_comments(page, sort: :best)
      assert Enum.map(comments, & &1.id) == [c2.id, c1.id]
    end

    test "sort: :new returns newest first", %{owner: user, page: page} do
      {:ok, c1} = CommentsContext.add_comment(page, user, %{body: "First"})
      {:ok, c2} = CommentsContext.add_comment(page, user, %{body: "Second"})

      %{items: comments} = CommentsContext.list_comments(page, sort: :new)
      assert Enum.map(comments, & &1.id) == [c2.id, c1.id]
    end

    test "sort: :old returns oldest first", %{owner: user, page: page} do
      {:ok, c1} = CommentsContext.add_comment(page, user, %{body: "First"})
      {:ok, c2} = CommentsContext.add_comment(page, user, %{body: "Second"})

      %{items: comments} = CommentsContext.list_comments(page, sort: :old)
      assert Enum.map(comments, & &1.id) == [c1.id, c2.id]
    end

    test "sort: :best is the default", %{owner: user, page: page} do
      voter = user_fixture()
      {:ok, c1} = CommentsContext.add_comment(page, user, %{body: "Low"})
      {:ok, c2} = CommentsContext.add_comment(page, user, %{body: "High"})
      {:ok, _} = CommentsContext.vote_comment(voter, c2.id, 1)

      %{items: comments} = CommentsContext.list_comments(page)
      assert Enum.map(comments, & &1.id) == [c2.id, c1.id]
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

  describe "vote_comment/3" do
    test "creates a vote", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      assert {:ok, vote} = CommentsContext.vote_comment(user, comment.id, 1)
      assert vote.value == 1
      assert vote.user_id == user.id
      assert vote.comment_id == comment.id
    end

    test "flips existing vote from +1 to -1", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      {:ok, _} = CommentsContext.vote_comment(user, comment.id, 1)
      {:ok, vote} = CommentsContext.vote_comment(user, comment.id, -1)
      assert vote.value == -1
    end

    test "same value is idempotent", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      {:ok, _} = CommentsContext.vote_comment(user, comment.id, 1)
      {:ok, vote} = CommentsContext.vote_comment(user, comment.id, 1)
      assert vote.value == 1
    end
  end

  describe "unvote_comment/2" do
    test "removes a vote", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      {:ok, _} = CommentsContext.vote_comment(user, comment.id, 1)
      assert :ok = CommentsContext.unvote_comment(user, comment.id)
      assert CommentsContext.comment_scores([comment.id]) == %{}
    end

    test "no-op when no vote exists", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      assert :ok = CommentsContext.unvote_comment(user, comment.id)
    end
  end

  describe "comment_scores/1" do
    test "returns correct net scores", %{owner: user, page: page} do
      comment = comment_fixture(page, user)
      user2 = user_fixture()
      user3 = user_fixture()

      {:ok, _} = CommentsContext.vote_comment(user, comment.id, 1)
      {:ok, _} = CommentsContext.vote_comment(user2, comment.id, 1)
      {:ok, _} = CommentsContext.vote_comment(user3, comment.id, -1)

      assert CommentsContext.comment_scores([comment.id]) == %{comment.id => 1}
    end

    test "returns empty map for no votes", %{page: page, owner: user} do
      comment = comment_fixture(page, user)
      assert CommentsContext.comment_scores([comment.id]) == %{}
    end

    test "returns empty map for empty list" do
      assert CommentsContext.comment_scores([]) == %{}
    end
  end

  describe "user_votes/2" do
    test "returns current user's votes", %{owner: user, page: page} do
      c1 = comment_fixture(page, user)
      c2 = comment_fixture(page, user)

      {:ok, _} = CommentsContext.vote_comment(user, c1.id, 1)
      {:ok, _} = CommentsContext.vote_comment(user, c2.id, -1)

      assert CommentsContext.user_votes(user, [c1.id, c2.id]) == %{c1.id => 1, c2.id => -1}
    end

    test "returns empty map for nil user", %{page: page, owner: user} do
      comment = comment_fixture(page, user)
      assert CommentsContext.user_votes(nil, [comment.id]) == %{}
    end

    test "returns empty map for empty list", %{owner: user} do
      assert CommentsContext.user_votes(user, []) == %{}
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
