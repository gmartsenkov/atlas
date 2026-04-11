defmodule AtlasWeb.CommentsSectionTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    Communities.join_community(member, community)
    page = page_fixture(community, owner)

    %{owner: owner, member: member, community: community, page: page, conn: conn}
  end

  defp page_path(community, page), do: ~p"/c/#{community.name}/#{page.slug}"

  defp upvote_button(comment_id), do: ~s(button[phx-click="upvote"][phx-value-id="#{comment_id}"])

  defp downvote_button(comment_id),
    do: ~s(button[phx-click="downvote"][phx-value-id="#{comment_id}"])

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

      html =
        lv
        |> element(upvote_button(comment.id))
        |> render_click()

      assert html =~ "text-success"

      scores = Communities.comment_scores([comment.id])
      assert scores[comment.id] == 1
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

      html =
        lv
        |> element(downvote_button(comment.id))
        |> render_click()

      assert html =~ "text-error"

      scores = Communities.comment_scores([comment.id])
      assert scores[comment.id] == -1
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

      scores = Communities.comment_scores([comment.id])
      assert scores == %{ comment.id => 1 }

      # Upvote again to toggle off
      lv |> element(upvote_button(comment.id)) |> render_click()

      scores = Communities.comment_scores([comment.id])
      assert scores == %{}
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

      scores = Communities.comment_scores([comment.id])
      assert scores == %{ comment.id => 1 }

      # Then downvote
      html = lv |> element(downvote_button(comment.id)) |> render_click()

      assert html =~ "text-error"

      scores = Communities.comment_scores([comment.id])
      assert scores == %{ comment.id => -1 }
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
      Communities.vote_comment(voter1, comment.id, 1)
      Communities.vote_comment(voter2, comment.id, 1)

      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # Score of 2 should appear with success styling
      assert html =~ "text-success font-semibold"
    end

    test "preserves user's existing vote highlight on page load", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      Communities.vote_comment(member, comment.id, 1)

      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      # The upvote button should be highlighted
      assert html =~ "text-success"
    end

    test "can vote on replies", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      {:ok, reply} = Communities.reply_to_comment(page, comment, owner, %{body: "A reply"})

      {:ok, lv, _html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      lv |> element(upvote_button(reply.id)) |> render_click()

      scores = Communities.comment_scores([reply.id])
      assert scores[reply.id] == 1
    end

    test "anonymous user cannot see vote buttons", %{
      conn: conn,
      community: community,
      page: page,
      owner: owner
    } do
      _comment = comment_fixture(page, owner)

      {:ok, _lv, html} = live(conn, page_path(community, page))

      refute html =~ "phx-click=\"upvote\""
      refute html =~ "phx-click=\"downvote\""
    end

    test "deleted comment does not show vote buttons", %{
      conn: conn,
      member: member,
      community: community,
      page: page,
      owner: owner
    } do
      comment = comment_fixture(page, owner)
      Communities.delete_comment(comment)

      {:ok, _lv, html} =
        conn |> log_in_user(member) |> live(page_path(community, page))

      assert html =~ "[Deleted]"
      refute html =~ "phx-click=\"upvote\""
      refute html =~ "phx-click=\"downvote\""
    end

    test "new comment starts with score of 0", %{
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
        |> render_click(%{"comment" => "Fresh comment"})

      assert html =~ "Fresh comment"
      # Score shows 0 with muted styling
      assert html =~ "text-base-content/40"
    end
  end
end
