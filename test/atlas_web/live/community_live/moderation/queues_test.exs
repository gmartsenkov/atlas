defmodule AtlasWeb.CommunityLive.Moderation.QueuesTest do
  use AtlasWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Atlas.AccountsFixtures
  import Atlas.CommunitiesFixtures

  alias Atlas.Communities
  alias Atlas.Communities.Sections

  setup %{conn: conn} do
    owner = user_fixture()
    community = community_fixture(owner)
    member = user_fixture()
    Communities.join_community(member, community)
    moderator = user_fixture()
    Communities.join_community(moderator, community)
    Communities.set_member_role(community, moderator.id, "moderator")
    author = user_fixture()
    Communities.join_community(author, community)
    page = page_fixture(community, owner)
    [section | _] = Sections.list_sections(page.id)

    %{
      owner: owner,
      member: member,
      moderator: moderator,
      author: author,
      community: community,
      page: page,
      section: section,
      conn: conn
    }
  end

  describe "access control" do
    test "non-moderator is redirected", %{conn: conn, member: member, community: community} do
      {:error, {:live_redirect, %{to: to, flash: flash}}} =
        conn |> log_in_user(member) |> live(~p"/mod/#{community.name}/queue")

      assert to == "/c/#{community.name}"
      assert flash["error"] =~ "permission"
    end
  end

  describe "empty queue" do
    test "shows all caught up when no pending proposals", %{
      conn: conn,
      owner: owner,
      community: community
    } do
      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      assert html =~ "All caught up!"
    end
  end

  describe "with pending proposals" do
    test "shows first pending proposal", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      assert html =~ author.nickname
      assert html =~ "Approve"
      assert html =~ "Reject"
      assert html =~ "Skip"
    end

    test "approve advances to next proposal", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)
      proposal_fixture(section, author)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      html = render_click(lv, "approve")
      assert html =~ "Proposal approved"
      # Should still show a proposal (the second one)
      assert html =~ "Approve"
    end

    test "reject advances to next proposal", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)
      proposal_fixture(section, author)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      html = render_click(lv, "reject")
      assert html =~ "Proposal rejected"
      assert html =~ "Approve"
    end

    test "skip shows next proposal and advances counter", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      _p1 = proposal_fixture(section, author)
      _p2 = proposal_fixture(section, author)

      {:ok, lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      assert html =~ "1 of 2"

      html = render_click(lv, "skip")
      assert html =~ "Approve"
      assert html =~ "2 of 2"
    end

    test "skipping the last wraps around to the first", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      _p1 = proposal_fixture(section, author)
      _p2 = proposal_fixture(section, author)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      # Skip both
      render_click(lv, "skip")
      html = render_click(lv, "skip")

      # Should wrap around, not show empty state
      assert html =~ "Approve"
      refute html =~ "All caught up"
      assert html =~ "1 of 2"
    end

    test "after last proposal shows empty state", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)

      {:ok, lv, _html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      html = render_click(lv, "approve")
      assert html =~ "All caught up!"
    end

    test "moderator can use queue", %{
      conn: conn,
      moderator: moderator,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)

      {:ok, _lv, html} =
        conn |> log_in_user(moderator) |> live(~p"/mod/#{community.name}/queue")

      assert html =~ "Approve"
    end

    test "shows X of Y counter", %{
      conn: conn,
      owner: owner,
      community: community,
      section: section,
      author: author
    } do
      proposal_fixture(section, author)
      proposal_fixture(section, author)

      {:ok, _lv, html} =
        conn |> log_in_user(owner) |> live(~p"/mod/#{community.name}/queue")

      assert html =~ "1 of 2"
    end
  end
end
