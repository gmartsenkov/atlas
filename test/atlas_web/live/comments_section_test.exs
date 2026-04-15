defmodule AtlasWeb.CommentsSectionTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities.CommentsContext
  alias Atlas.Communities.CommunityManager

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    CommunityManager.join_community(member, community)
    page = page_fixture(community, owner)

    %{owner: owner, member: member, community: community, page: page, conn: conn}
  end

  defp page_path(community, page), do: ~p"/c/#{community.name}/#{page.slug}"

  defp upvote_button(id), do: ~s([data-testid="upvote-#{id}"])
  defp downvote_button(id), do: ~s([data-testid="downvote-#{id}"])
  defp vote_score(id), do: ~s([data-testid="vote-score-#{id}"])
  defp vote_controls(id), do: ~s(data-testid="vote-controls-#{id}")

  describe "commenting" do
    test "logged-in user can add a comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      html =
        lv
        |> element("#comments button", "Comment")
        |> render_click(%{"comment" => "Hello world"})

      assert html =~ "Hello world"
    end

    test "logged-in user can reply to a comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # Click Reply button to show the form
      lv
      |> element(~s(button[phx-click="start-reply"][phx-value-id="#{comment.id}"]))
      |> render_click()

      html = render(lv)
      assert html =~ "Write a reply"
    end

    test "anonymous user sees login prompt", %{conn: conn, community: community, page: page} do
      {:ok, _lv, html} = live(conn, page_path(community, page))

      assert html =~ "Log in"
      assert html =~ "to join the discussion"
    end
  end

  describe "sorting" do
    test "default sort is best", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment_fixture(page, owner, %{body: "A comment"})

      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # Sort dropdown is present with all options
      assert html =~ ~s(phx-value-sort="best")
      assert html =~ ~s(phx-value-sort="new")
      assert html =~ ~s(phx-value-sort="old")

      # Current sort label shown on the trigger button
      assert html =~ "Best"
    end

    test "clicking sort tab reloads comments in new order", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      voter = user_fixture()
      c1 = comment_fixture(page, owner, %{body: "OlderComment"})
      _c2 = comment_fixture(page, owner, %{body: "NewerComment"})
      CommentsContext.vote_comment(voter, c1.id, 1)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # Default is best — c1 (1 vote) should come before c2 (0 votes)
      html = render(lv)
      assert comment_order(html, "OlderComment", "NewerComment") == :first

      # Switch to "New" — c2 (newer) should come first
      lv
      |> element(~s(button[phx-value-sort="new"]))
      |> render_click()

      html = render(lv)
      assert comment_order(html, "NewerComment", "OlderComment") == :first
    end

    test "sort tabs are hidden when no comments", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      refute html =~ ~s(phx-value-sort="best")
    end
  end

  describe "deleting comments" do
    defp delete_button(id), do: ~s(button[phx-click="delete-comment"][phx-value-id="#{id}"])

    test "author can delete their own comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      comment = comment_fixture(page, member, %{body: "My comment"})

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      assert has_element?(lv, delete_button(comment.id))

      lv |> element(delete_button(comment.id)) |> render_click()

      html = render(lv)
      assert html =~ "[Deleted]"
      refute html =~ "My comment"

      assert {:ok, %{deleted: true}} = CommentsContext.get_comment(comment.id)
    end

    test "community owner can delete any comment", %{
      conn: conn,
      owner: owner,
      member: member,
      community: community,
      page: page
    } do
      comment = comment_fixture(page, member, %{body: "Member comment"})

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(page_path(community, page))

      assert has_element?(lv, delete_button(comment.id))

      lv |> element(delete_button(comment.id)) |> render_click()

      html = render(lv)
      assert html =~ "[Deleted]"
      refute html =~ "Member comment"

      assert {:ok, %{deleted: true}} = CommentsContext.get_comment(comment.id)
    end

    test "moderator can delete any comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      moderator = user_fixture()
      CommunityManager.join_community(moderator, community)
      CommunityManager.set_member_role(community, moderator.id, "moderator")

      comment = comment_fixture(page, member, %{body: "Member comment"})

      {:ok, lv, _html} =
        conn |> log_in_user(moderator) |> live(page_path(community, page))

      assert has_element?(lv, delete_button(comment.id))

      lv |> element(delete_button(comment.id)) |> render_click()

      html = render(lv)
      assert html =~ "[Deleted]"
      refute html =~ "Member comment"

      assert {:ok, %{deleted: true}} = CommentsContext.get_comment(comment.id)
    end

    test "other member cannot delete someone else's comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner, %{body: "Owner comment"})

      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      refute html =~ ~s(phx-click="delete-comment" phx-value-id="#{comment.id}")
    end

    test "author can delete their own reply", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      {:ok, reply} = CommentsContext.reply_to_comment(page, comment, member, %{body: "My reply"})

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      assert has_element?(lv, delete_button(reply.id))

      lv |> element(delete_button(reply.id)) |> render_click()

      html = render(lv)
      assert html =~ "[Deleted]"
      refute html =~ "My reply"

      assert {:ok, %{deleted: true}} = CommentsContext.get_comment(reply.id)
    end
  end

  describe "voting" do
    test "logged-in user can upvote a comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      lv |> element(upvote_button(comment.id)) |> render_click()

      assert element(lv, upvote_button(comment.id)) |> render() =~ "text-success"
      assert element(lv, vote_score(comment.id)) |> render() =~ "1"

      assert CommentsContext.comment_scores([comment.id]) == %{comment.id => 1}
    end

    test "logged-in user can downvote a comment", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      lv |> element(downvote_button(comment.id)) |> render_click()

      assert element(lv, downvote_button(comment.id)) |> render() =~ "text-error"
      assert element(lv, vote_score(comment.id)) |> render() =~ "-1"

      assert CommentsContext.comment_scores([comment.id]) == %{comment.id => -1}
    end

    test "clicking same vote direction toggles it off", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # Upvote
      lv |> element(upvote_button(comment.id)) |> render_click()
      assert CommentsContext.comment_scores([comment.id]) == %{comment.id => 1}

      # Upvote again to toggle off
      lv |> element(upvote_button(comment.id)) |> render_click()
      assert CommentsContext.comment_scores([comment.id]) == %{}

      assert element(lv, vote_score(comment.id)) |> render() =~ "0"
    end

    test "switching vote direction flips the vote", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # Upvote first
      lv |> element(upvote_button(comment.id)) |> render_click()
      assert CommentsContext.comment_scores([comment.id]) == %{comment.id => 1}

      # Then downvote
      lv |> element(downvote_button(comment.id)) |> render_click()

      assert element(lv, downvote_button(comment.id)) |> render() =~ "text-error"
      assert element(lv, vote_score(comment.id)) |> render() =~ "-1"

      assert CommentsContext.comment_scores([comment.id]) == %{comment.id => -1}
    end

    test "displays existing vote scores on page load", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      voter1 = user_fixture()
      voter2 = user_fixture()
      CommentsContext.vote_comment(voter1, comment.id, 1)
      CommentsContext.vote_comment(voter2, comment.id, 1)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      score_html = element(lv, vote_score(comment.id)) |> render()
      assert score_html =~ "2"
      assert score_html =~ "text-success"
    end

    test "preserves user's existing vote highlight on page load", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      CommentsContext.vote_comment(member, comment.id, 1)

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      assert element(lv, upvote_button(comment.id)) |> render() =~ "text-success"
    end

    test "can vote on replies", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      {:ok, reply} = CommentsContext.reply_to_comment(page, comment, owner, %{body: "A reply"})

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      lv |> element(upvote_button(reply.id)) |> render_click()

      assert CommentsContext.comment_scores([reply.id]) == %{reply.id => 1}
    end

    test "anonymous user cannot see vote buttons", %{
      conn: conn,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)

      {:ok, _lv, html} = live(conn, page_path(community, page))

      refute html =~ "data-testid=\"upvote-#{comment.id}\""
      refute html =~ "data-testid=\"downvote-#{comment.id}\""
    end

    test "deleted comment does not show vote buttons", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      CommentsContext.delete_comment(comment)

      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      assert html =~ "[Deleted]"
      refute html =~ vote_controls(comment.id)
    end

    test "new comment starts with score of 0", %{
      conn: conn,
      member: member,
      community: community,
      page: page
    } do
      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      lv
      |> element("#comments button", "Comment")
      |> render_click(%{"comment" => "Fresh comment"})

      html = render(lv)
      assert html =~ "Fresh comment"
      assert html =~ "text-base-content/40"
    end
  end

  # Returns :first if text_a appears before text_b in the HTML
  defp comment_order(html, text_a, text_b) do
    pos_a = :binary.match(html, text_a) |> elem(0)
    pos_b = :binary.match(html, text_b) |> elem(0)
    if pos_a < pos_b, do: :first, else: :second
  end
end
