defmodule Atlas.Communities.Comment.VoteTest do
  use Atlas.DataCase, async: true

  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.Comment.Vote
  alias Atlas.Communities.CommentsContext

  setup do
    owner = user_fixture()
    community = community_fixture(owner)
    page = page_fixture(community, owner)
    comment = comment_fixture(page, owner)

    %{comment: comment}
  end

  describe "cast/3" do
    test "upvotes a comment", %{comment: comment} do
      voter = user_fixture()

      assert {:ok, vote} = Vote.cast(voter, comment.id, 1)
      assert vote.value == 1

      scores = CommentsContext.comment_scores([comment.id])
      assert scores[comment.id] == 1
    end

    test "downvotes a comment", %{comment: comment} do
      voter = user_fixture()

      assert {:ok, vote} = Vote.cast(voter, comment.id, -1)
      assert vote.value == -1
    end

    test "changes vote from up to down", %{comment: comment} do
      voter = user_fixture()
      {:ok, _} = Vote.cast(voter, comment.id, 1)

      assert {:ok, vote} = Vote.cast(voter, comment.id, -1)
      assert vote.value == -1

      scores = CommentsContext.comment_scores([comment.id])
      assert scores[comment.id] == -1
    end
  end

  describe "remove/2" do
    test "removes a vote", %{comment: comment} do
      voter = user_fixture()
      {:ok, _} = Vote.cast(voter, comment.id, 1)

      assert :ok = Vote.remove(voter, comment.id)

      votes = CommentsContext.user_votes(voter, [comment.id])
      assert votes == %{}
    end

    test "removing a non-existent vote is a no-op", %{comment: comment} do
      voter = user_fixture()

      assert :ok = Vote.remove(voter, comment.id)
    end
  end
end
